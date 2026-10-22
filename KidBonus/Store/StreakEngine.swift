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
    /// 当日首次加分时调用。返回新的 streak count 与触发的奖励列表。
    /// 业务规则：
    ///   当日已加分 → 不变, 不发奖
    ///   lastDate == 昨天 → count + 1
    ///   否则         → count = 1
    /// 奖励由 BonusRule 决定：连续天数是规则天数的整数倍时发一次，
    /// 所以 7 天规则会在 7/14/21… 天发，30 天规则会在 30/60… 天发。
    @MainActor
    static func bump(kidID: UUID, ctx: ModelContext) -> StreakUpdate {
        let today = DateKey.today
        let streak = currentStreak(kidID: kidID, ctx: ctx)
        let prev = streak ?? Streak(kidID: kidID)
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

        return StreakUpdate(count: nextCount, awards: BonusRules.awards(for: nextCount, ctx: ctx))
    }

    @MainActor
    static func currentStreak(kidID: UUID, ctx: ModelContext) -> Streak? {
        let pred = #Predicate<Streak> { $0.kidID == kidID }
        return try? ctx.fetch(FetchDescriptor<Streak>(predicate: pred)).first
    }
}
