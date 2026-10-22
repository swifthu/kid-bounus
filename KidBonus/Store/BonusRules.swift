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
    /// 预设项的记录里存的是项目 id，撤销时好把「用了几次」加回去
    let sourceId: String?

    init(_ record: HistoryRecord) {
        kidID = record.kid?.id
        title = record.title
        delta = record.delta
        timestamp = record.timestamp
        sourceKind = record.sourceKind
        sourceId = record.sourceId
    }
}

/// 连续天数的奖励规则读取与匹配。
enum BonusRules {
    /// 启用中的规则，按天数从少到多。项目已被删除的规则不再参与。
    @MainActor
    static func active(ctx: ModelContext) -> [BonusRule] {
        let rules = (try? ctx.fetch(FetchDescriptor<BonusRule>())) ?? []
        let usable = rules.filter { $0.enabled && $0.days > 0 && $0.itemID != nil }
        return usable.sorted { $0.days < $1.days }
    }

    /// 某个项目的连续天数命中了哪些规则：连续天数是规则天数的整数倍时发奖，
    /// 7 天规则在 7/14/21… 天发，30 天规则在 30/60… 天发。
    @MainActor
    static func awards(for streakCount: Int, itemID: UUID, ctx: ModelContext) -> [StreakAward] {
        guard streakCount > 0 else { return [] }
        let matched = active(ctx: ctx).filter {
            $0.itemID == itemID && streakCount % $0.days == 0
        }
        return matched.map { StreakAward(days: $0.days, points: $0.points) }
    }

    /// 同一个项目、同一个周期只能有一条规则：连续满 N 天会同时发两份奖。
    /// `excluding` 是正在编辑的那条规则，改它自己不算重复。
    @MainActor
    static func hasRule(days: Int, itemID: UUID, excluding id: UUID?, ctx: ModelContext) -> Bool {
        let rules = (try? ctx.fetch(FetchDescriptor<BonusRule>())) ?? []
        return rules.contains { $0.itemID == itemID && $0.days == days && $0.id != id }
    }

    /// 挂在某个项目上的规则。
    @MainActor
    static func rules(forItem itemID: UUID, ctx: ModelContext) -> [BonusRule] {
        let rules = (try? ctx.fetch(FetchDescriptor<BonusRule>())) ?? []
        return rules.filter { $0.itemID == itemID }.sorted { $0.days < $1.days }
    }
}
