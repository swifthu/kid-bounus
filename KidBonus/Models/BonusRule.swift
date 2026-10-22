import Foundation
import SwiftData

/// 连续天数奖励规则：连续每满 days 天，奖励 points 分。
/// 规则是全局的，对两个孩子都生效。
@Model
final class BonusRule {
    @Attribute(.unique) var id: UUID
    /// 连续多少天发一次
    var days: Int
    /// 奖励多少分
    var points: Int
    var enabled: Bool

    init(id: UUID = UUID(), days: Int, points: Int, enabled: Bool = true) {
        self.id = id
        self.days = days
        self.points = points
        self.enabled = enabled
    }
}
