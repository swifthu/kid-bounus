import Foundation
import SwiftData

enum RecordStore {
    struct WriteOutcome {
        var points: Int
        var streakBonus: Int
        var streakCount: Int
        /// 触发的奖励明细，用于逐条写进历程
        var awards: [StreakAward] = []
    }

    /// 写一条 history（积分项）。加分时自动触发 streak + bonus。
    @MainActor
    static func recordItem(_ item: PointItem, on kid: Kid, ctx: ModelContext) -> WriteOutcome {
        ctx.insert(HistoryRecord(
            kid: kid,
            title: item.title,
            delta: item.delta,
            sourceKind: .preset,
            sourceId: item.id.uuidString
        ))

        // 用了几次，首页按它排「最近常用」
        item.usageCount += 1

        var awards: [StreakAward] = []
        var streakCount = 0
        if item.delta > 0 {
            let r = StreakEngine.bump(kidID: kid.id, ctx: ctx)
            streakCount = r.count
            awards = r.awards
            for award in awards {
                ctx.insert(HistoryRecord(
                    kid: kid,
                    title: "连续 \(award.days) 天 bonus",
                    delta: award.points,
                    sourceKind: .streakBonus,
                    sourceId: "streak-bonus"
                ))
            }
        }
        try? ctx.save()
        return WriteOutcome(
            points: PointMath.kidPoints(kid),
            streakBonus: awards.reduce(0) { $0 + $1.points },
            streakCount: streakCount,
            awards: awards
        )
    }

    /// 写一条 freeform history。
    @MainActor
    static func recordFreeform(title: String, delta: Int, on kid: Kid,
                               ctx: ModelContext) -> WriteOutcome {
        ctx.insert(HistoryRecord(
            kid: kid,
            title: title,
            delta: delta,
            sourceKind: .freeform,
            sourceId: "freeform-\(UUID().uuidString)"
        ))

        var awards: [StreakAward] = []
        var streakCount = 0
        if delta > 0 {
            let r = StreakEngine.bump(kidID: kid.id, ctx: ctx)
            streakCount = r.count
            awards = r.awards
            for award in awards {
                ctx.insert(HistoryRecord(
                    kid: kid,
                    title: "连续 \(award.days) 天 bonus",
                    delta: award.points,
                    sourceKind: .streakBonus,
                    sourceId: "streak-bonus"
                ))
            }
        }
        try? ctx.save()
        return WriteOutcome(
            points: PointMath.kidPoints(kid),
            streakBonus: awards.reduce(0) { $0 + $1.points },
            streakCount: streakCount,
            awards: awards
        )
    }

    /// 兑换商品。
    @MainActor
    static func redeem(_ product: Product, by kid: Kid, ctx: ModelContext) -> Bool {
        guard PointMath.kidPoints(kid) >= product.cost else { return false }
        ctx.insert(Redemption(
            kid: kid,
            productName: product.name,
            cost: product.cost
        ))
        try? ctx.save()
        return true
    }

    /// 直接设定总积分，差额记一条历史，方便回溯。返回设定后的积分。
    @MainActor
    static func setPoints(_ target: Int, for kid: Kid, ctx: ModelContext) -> Int {
        let current = PointMath.kidPoints(kid)
        let delta = target - current
        if delta != 0 {
            ctx.insert(HistoryRecord(
                kid: kid,
                title: "设定积分为 \(target)",
                delta: delta,
                sourceKind: .adjust
            ))
            try? ctx.save()
        }
        return PointMath.kidPoints(kid)
    }

    /// 删掉一条记录并回调积分。积分由历史与兑换汇总得出，所以删掉即回调，
    /// 不需要额外写一条反向记录。返回回调后该孩子的积分。
    @MainActor
    static func deleteRecord(_ record: HistoryRecord, ctx: ModelContext) -> Int {
        let kid = record.kid
        // 这条记录用掉的预设项次数也要退回去，「最近常用」才和实际一致
        adjustUsage(sourceId: record.sourceId, by: -1, ctx: ctx)
        ctx.delete(record)
        try? ctx.save()
        return kid.map(PointMath.kidPoints) ?? 0
    }

    /// 删掉一条兑换记录，兑换花掉的分会回到孩子账上。返回退回后的积分。
    @MainActor
    static func deleteRedemption(_ redemption: Redemption, ctx: ModelContext) -> Int {
        let kid = redemption.kid
        ctx.delete(redemption)
        try? ctx.save()
        return kid.map(PointMath.kidPoints) ?? 0
    }

    /// 撤销删除：按快照重新写一条记录。返回恢复后的积分。
    @MainActor
    static func restore(_ snapshot: HistorySnapshot, ctx: ModelContext) -> Int {
        guard let kid = kid(withID: snapshot.kidID, ctx: ctx) else { return 0 }
        ctx.insert(HistoryRecord(
            kid: kid,
            title: snapshot.title,
            delta: snapshot.delta,
            timestamp: snapshot.timestamp,
            sourceKind: snapshot.sourceKind,
            sourceId: snapshot.sourceId
        ))
        // 记录回来了，预设项的次数也得加回去
        adjustUsage(sourceId: snapshot.sourceId, by: 1, ctx: ctx)
        try? ctx.save()
        return PointMath.kidPoints(kid)
    }

    /// 预设项的记录里 sourceId 存的是项目 id（自由记录和 bonus 存的是别的串），
    /// 用它把「用了几次」一起加减，首页的「最近常用」才不会和实际对不上。
    @MainActor
    private static func adjustUsage(sourceId: String?, by delta: Int, ctx: ModelContext) {
        guard let sourceId, let uuid = UUID(uuidString: sourceId) else { return }
        let pred = #Predicate<PointItem> { $0.id == uuid }
        guard let item = try? ctx.fetch(FetchDescriptor<PointItem>(predicate: pred)).first else { return }
        item.usageCount = max(0, item.usageCount + delta)
    }

    /// 撤销撤销兑换：把花掉的分还回去。返回恢复后的积分。
    @MainActor
    static func restoreRedemption(_ snapshot: RedemptionSnapshot, ctx: ModelContext) -> Int {
        guard let kid = kid(withID: snapshot.kidID, ctx: ctx) else { return 0 }
        ctx.insert(Redemption(
            kid: kid,
            productName: snapshot.productName,
            cost: snapshot.cost,
            timestamp: snapshot.timestamp
        ))
        try? ctx.save()
        return PointMath.kidPoints(kid)
    }

    @MainActor
    private static func kid(withID id: UUID?, ctx: ModelContext) -> Kid? {
        guard let id else { return nil }
        let pred = #Predicate<Kid> { $0.id == id }
        return try? ctx.fetch(FetchDescriptor<Kid>(predicate: pred)).first
    }
}
