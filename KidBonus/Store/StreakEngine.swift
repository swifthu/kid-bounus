import Foundation
import SwiftData

struct StreakUpdate: Equatable { var count: Int; var bonus: Int }

enum StreakEngine {
    static let weeklyBonus = 20
    static let monthlyBonus = 100

    /// 当日首次加分时调用。返回新的 streak count 与触发的 bonus（0 或 20 或 100）。
    /// 业务规则：
    ///   当日已加分 → 不变, bonus = 0
    ///   lastDate == 昨天 → count + 1
    ///   否则         → count = 1
    ///   count == 7  → bonus = 20
    ///   count == 30 → bonus += 100
    static func bump(kidID: UUID, ctx: ModelContext) -> StreakUpdate {
        let today = DateKey.today
        let streak = currentStreak(kidID: kidID, ctx: ctx)
        let prev = streak ?? Streak(kidID: kidID)
        if streak == nil { ctx.insert(prev) }

        if prev.lastDateKey == today {
            return StreakUpdate(count: prev.count, bonus: 0)
        }

        let yesterday = DateKey.day(before: 1)
        let nextCount: Int
        if prev.lastDateKey == yesterday {
            nextCount = prev.count + 1
        } else {
            nextCount = 1
        }

        var bonus = 0
        if nextCount == 7  { bonus = weeklyBonus }
        if nextCount == 30 { bonus += monthlyBonus }

        prev.count = nextCount
        prev.lastDateKey = today
        try? ctx.save()

        return StreakUpdate(count: nextCount, bonus: bonus)
    }

    static func currentStreak(kidID: UUID, ctx: ModelContext) -> Streak? {
        let pred = #Predicate<Streak> { $0.kidID == kidID }
        return try? ctx.fetch(FetchDescriptor<Streak>(predicate: pred)).first
    }
}
