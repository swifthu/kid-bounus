import Foundation
import SwiftData

/// 删掉一条历史记录后，撤销要用的数据副本。
/// 记录本身已经被删掉，撤销时按这份快照重新写一条。
struct HistorySnapshot: Equatable {
    let kidID: UUID?
    let title: String
    let delta: Int
    let timestamp: Date
    let sourceKind: SourceKind

    init(_ record: HistoryRecord) {
        kidID = record.kid?.id
        title = record.title
        delta = record.delta
        timestamp = record.timestamp
        sourceKind = record.sourceKind
    }
}

/// 连续天数的奖励规则读取与匹配。
enum BonusRules {
    /// 启用中的规则，按天数从少到多。
    @MainActor
    static func active(ctx: ModelContext) -> [BonusRule] {
        let rules = (try? ctx.fetch(FetchDescriptor<BonusRule>())) ?? []
        return rules.filter { $0.enabled && $0.days > 0 }.sorted { $0.days < $1.days }
    }

    /// 连续天数正好是规则天数的整数倍时发奖：7 天规则在 7/14/21… 天发，30 天规则在 30/60… 天发。
    @MainActor
    static func awards(for streakCount: Int, ctx: ModelContext) -> [StreakAward] {
        guard streakCount > 0 else { return [] }
        return active(ctx: ctx)
            .filter { streakCount % $0.days == 0 }
            .map { StreakAward(days: $0.days, points: $0.points) }
    }
}
