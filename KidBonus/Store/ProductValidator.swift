import Foundation

enum ProductValidationError: Error, Equatable {
    case emptyName
    case invalidCost
}

struct ProductDraft: Equatable {
    let name: String
    let cost: Int
    let category: ProductCategory
    var iconName: String?
    let desc: String
}

/// 新增 / 编辑商品的输入校验与归一化。
enum ProductValidator {
    /// 名称不能为空；分值必须是正整数 —— 0 或负数的商品永远无法兑换。
    /// 图标名留空则由卡片回退到默认图标，说明留空用通用文案。
    static func validate(name: String, costText: String, category: ProductCategory,
                         iconText: String, descText: String) throws -> ProductDraft {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw ProductValidationError.emptyName }

        let cost = Int(costText.trimmingCharacters(in: .whitespacesAndNewlines))
        guard let cost, cost > 0 else { throw ProductValidationError.invalidCost }

        let icon = iconText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDesc = descText.trimmingCharacters(in: .whitespacesAndNewlines)

        return ProductDraft(
            name: trimmedName,
            cost: cost,
            category: category,
            iconName: icon.isEmpty ? nil : icon,
            desc: trimmedDesc.isEmpty ? "兑换奖励" : trimmedDesc
        )
    }
}
