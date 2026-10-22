import Foundation

enum BonusRuleValidationError: Error, Equatable {
    case emptyDays
    case invalidDays
    case emptyPoints
    case invalidPoints
}

struct BonusRuleDraft: Equatable {
    let days: Int
    let points: Int
}

/// bonus 规则的输入校验与归一化。
enum BonusRuleValidator {
    /// 连续天数至少 1 天；奖励分值至少 1 分。
    /// 0 分的规则没意义：历程里只会多一条 +0 的记录，也不会有任何提示。
    /// 不想发奖直接停用这条规则就行。
    static func validate(daysText: String, pointsText: String) throws -> BonusRuleDraft {
        let daysText = daysText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !daysText.isEmpty else { throw BonusRuleValidationError.emptyDays }
        guard let days = Int(daysText), days > 0 else { throw BonusRuleValidationError.invalidDays }

        let pointsText = pointsText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pointsText.isEmpty else { throw BonusRuleValidationError.emptyPoints }
        guard let points = Int(pointsText), points > 0 else { throw BonusRuleValidationError.invalidPoints }

        return BonusRuleDraft(days: days, points: points)
    }
}
