import Foundation

enum ItemValidationError: Error, Equatable {
    case emptyTitle
    case invalidDelta
}

struct ItemDraft: Equatable {
    let title: String
    let delta: Int
    let desc: String
}

/// 新增积分项的输入校验与归一化。
enum ItemValidator {
    /// 分值符号强制与 kind 一致：加分项恒为正，扣分项恒为负（用户输反了也纠正）。
    /// 描述留空时按 kind 填默认文案。
    static func validate(kind: Kind, title: String, deltaText: String, descText: String) throws -> ItemDraft {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { throw ItemValidationError.emptyTitle }

        let raw = Int(deltaText.trimmingCharacters(in: .whitespacesAndNewlines))
        guard let raw, raw != 0 else { throw ItemValidationError.invalidDelta }

        var delta = raw
        if kind == .add && delta < 0 { delta = -delta }
        if kind == .deduct && delta > 0 { delta = -delta }

        let trimmedDesc = descText.trimmingCharacters(in: .whitespacesAndNewlines)
        let desc = trimmedDesc.isEmpty
            ? (kind == .add ? "一个好习惯" : "需要改进的小事")
            : trimmedDesc

        return ItemDraft(title: trimmedTitle, delta: delta, desc: desc)
    }

    static func defaultIconName(for kind: Kind) -> String {
        kind == .add ? "checkmark" : "exclamationmark"
    }
}
