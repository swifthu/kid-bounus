import Foundation
import SwiftData

struct StreakUpdate: Equatable { var count: Int; var awards: [StreakAward] }

/// 一条奖励规则的触发结果。
struct StreakAward: Equatable {
    /// 规则的周期天数，如 7 表示「每连续 7 天」
    let days: Int
    let points: Int
}

enum StreakEngine {
    /// 某个孩子做某个加分项的连续天数。返回新的连续天数与触发的奖励列表。
    /// 业务规则：
    ///   当日已做过 → 不变, 不发奖
    ///   lastDateKey == 昨天 → count + 1
    ///   否则         → count = 1
    /// 奖励由 BonusRule 决定：连续天数是规则天数的整数倍时发一次，
    /// 所以 7 天规则会在 7/14/21… 天发，30 天规则会在 30/60… 天发。
    @MainActor
    static func bump(kidID: UUID, itemID: UUID, ctx: ModelContext) -> StreakUpdate {
        let today = DateKey.today
        let streak = currentStreak(kidID: kidID, itemID: itemID, ctx: ctx)
        let prev = streak ?? Streak(kidID: kidID, itemID: itemID)
        if streak == nil { ctx.insert(prev) }

        if prev.lastDateKey == today {
            return StreakUpdate(count: prev.count, awards: [])
        }

        let yesterday = DateKey.day(before: 1)
        let nextCount: Int
        if prev.lastDateKey == yesterday {
            nextCount = prev.count + 1
        } else {
            nextCount = 1
        }

        prev.count = nextCount
        prev.lastDateKey = today
        try? ctx.save()

        return StreakUpdate(count: nextCount,
                            awards: BonusRules.awards(for: nextCount, itemID: itemID, ctx: ctx))
    }

    /// 某个孩子在某个项目上的连续天数。
    @MainActor
    static func currentStreak(kidID: UUID, itemID: UUID, ctx: ModelContext) -> Streak? {
        streaks(kidID: kidID, ctx: ctx).first { $0.itemID == itemID }
    }

    /// 这个孩子所有项目里最长的、还算数的连续天数。
    /// 只有今天或昨天还在做的项目才算「还算数」，断了很久的不再显示。
    @MainActor
    static func bestLiveStreak(kidID: UUID, ctx: ModelContext) -> (days: Int, itemID: UUID?) {
        let live = streaks(kidID: kidID, ctx: ctx)
            .filter { $0.itemID != nil && isLive($0.lastDateKey) }
        guard let best = live.max(by: { $0.count < $1.count }) else { return (0, nil) }
        return (best.count, best.itemID)
    }

    /// 从历史重新数某个项目的连续天数。
    /// 删除或撤销记录后调用，免得删掉的那天还留在连续天数里。
    @MainActor
    static func recompute(kidID: UUID, itemID: UUID, ctx: ModelContext) {
        guard let kid = kid(withID: kidID, ctx: ctx),
              let streak = currentStreak(kidID: kidID, itemID: itemID, ctx: ctx) else { return }

        // 预设项的记录里 sourceId 存的就是项目 id
        let records = kid.history.filter {
            $0.sourceKind == .preset && $0.sourceId == itemID.uuidString
        }
        let days = Set(records.map { DateKey.day($0.timestamp) })

        guard let last = days.max() else {
            streak.count = 0
            streak.lastDateKey = nil
            return
        }

        var count = 0
        var cursor: String? = last
        while let day = cursor, days.contains(day) {
            count += 1
            cursor = DateKey.previousDay(of: day)
        }
        streak.count = count
        streak.lastDateKey = last
    }

    /// 连续天数是否还「热着」：今天或昨天做过。
    @MainActor
    static func isLive(_ lastDateKey: String?) -> Bool {
        guard let lastDateKey else { return false }
        return lastDateKey == DateKey.today || lastDateKey == DateKey.day(before: 1)
    }

    @MainActor
    private static func streaks(kidID: UUID, ctx: ModelContext) -> [Streak] {
        let pred = #Predicate<Streak> { $0.kidID == kidID }
        return (try? ctx.fetch(FetchDescriptor<Streak>(predicate: pred))) ?? []
    }

    @MainActor
    private static func kid(withID id: UUID, ctx: ModelContext) -> Kid? {
        let pred = #Predicate<Kid> { $0.id == id }
        return try? ctx.fetch(FetchDescriptor<Kid>(predicate: pred)).first
    }
}
