import Foundation

enum BonusRuleValidationError: Error, Equatable {
    case invalidDays
    case invalidPoints
}

struct BonusRuleDraft: Equatable {
    let days: Int
    let points: Int
}

/// bonus 规则的输入校验与归一化。
enum BonusRuleValidator {
    /// 连续天数至少 1 天；奖励分值不能为负（可以是 0，表示只做庆祝不发分）。
    static func validate(daysText: String, pointsText: String) throws -> BonusRuleDraft {
        let days = Int(daysText.trimmingCharacters(in: .whitespacesAndNewlines))
        guard let days, days > 0 else { throw BonusRuleValidationError.invalidDays }

        let points = Int(pointsText.trimmingCharacters(in: .whitespacesAndNewlines))
        guard let points, points >= 0 else { throw BonusRuleValidationError.invalidPoints }

        return BonusRuleDraft(days: days, points: points)
    }
}
