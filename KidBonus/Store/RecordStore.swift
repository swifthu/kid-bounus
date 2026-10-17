import Foundation
import SwiftData

enum RecordStore {
    struct WriteOutcome {
        var points: Int
        var streakBonus: Int
        var streakCount: Int
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

        var bonus = 0
        var streakCount = 0
        if item.delta > 0 {
            let r = StreakEngine.bump(kidID: kid.id, ctx: ctx)
            streakCount = r.count
            if r.bonus > 0 {
                ctx.insert(HistoryRecord(
                    kid: kid,
                    title: "连续 \(r.count) 天 bonus",
                    delta: r.bonus,
                    sourceKind: .streakBonus,
                    sourceId: "streak-bonus"
                ))
                bonus = r.bonus
            }
        }
        try? ctx.save()
        return WriteOutcome(
            points: PointMath.kidPoints(kid),
            streakBonus: bonus,
            streakCount: streakCount
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

        var bonus = 0
        var streakCount = 0
        if delta > 0 {
            let r = StreakEngine.bump(kidID: kid.id, ctx: ctx)
            streakCount = r.count
            if r.bonus > 0 {
                ctx.insert(HistoryRecord(
                    kid: kid,
                    title: "连续 \(r.count) 天 bonus",
                    delta: r.bonus,
                    sourceKind: .streakBonus,
                    sourceId: "streak-bonus"
                ))
                bonus = r.bonus
            }
        }
        try? ctx.save()
        return WriteOutcome(
            points: PointMath.kidPoints(kid),
            streakBonus: bonus,
            streakCount: streakCount
        )
    }

    /// 兑换商品。
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
}
