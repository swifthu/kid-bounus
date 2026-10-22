import Foundation
import SwiftData

/// 连续天数奖励规则：某个加分项目上连续每满 days 天，奖励 points 分。
/// 规则挂在具体项目上：孩子坚持的是哪件事，就给哪件事设规则。
@Model
final class BonusRule {
    @Attribute(.unique) var id: UUID
    /// 针对哪个加分项。nil 表示项目已被删除，这条规则已失效。
    var itemID: UUID?
    /// 连续多少天发一次
    var days: Int
    /// 奖励多少分
    var points: Int
    var enabled: Bool

    init(id: UUID = UUID(), itemID: UUID? = nil, days: Int, points: Int, enabled: Bool = true) {
        self.id = id
        self.itemID = itemID
        self.days = days
        self.points = points
        self.enabled = enabled
    }
}
