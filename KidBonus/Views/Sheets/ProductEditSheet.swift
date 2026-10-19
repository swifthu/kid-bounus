import SwiftUI
import SwiftData

/// 商品的新增 / 编辑表单。`product` 为 nil 时是新增。
struct ProductEditSheet: View {
    let product: Product?
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toast
    @State private var name: String = ""
    @State private var costText: String = ""
    @State private var category: ProductCategory = .toy
    @State private var iconText: String = ""
    @State private var desc: String = ""
    @State private var loaded = false

    var body: some View {
        SheetScaffold(
            title: product == nil ? "新增商品" : "编辑商品",
            message: "名称与分值必填，分值要大于 0。",
            actions: [
                SheetAction(title: "取消", primary: false) { dismiss() },
                SheetAction(title: "保存", primary: true) { save() }
            ]
        ) {
            Field(text: $name, placeholder: "商品名称，如：乐高积木")
            Field(text: $costText, placeholder: "所需分数（整数）", keyboard: .numberPad)

            Picker("分类", selection: $category) {
                ForEach(ProductCategory.allCases) { c in
                    Text(c.label).tag(c)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.kami.accent)
            .padding(Spacing.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.kami.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(Color.kami.border, lineWidth: 1)
            )

            Field(text: $iconText, placeholder: "SF Symbol 名（可选）")
            Field(text: $desc, placeholder: "一句说明（可选）")
        }
        .onAppear(perform: loadIfNeeded)
    }

    /// 表单只在弹层出现时回填一次，避免用户输入后被 @Query 刷新覆盖。
    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        guard let product else { return }
        name = product.name
        costText = "\(product.cost)"
        category = product.category
        iconText = product.iconName ?? ""
        desc = product.desc
    }

    private func save() {
        let draft: ProductDraft
        do {
            draft = try ProductValidator.validate(
                name: name, costText: costText, category: category,
                iconText: iconText, descText: desc
            )
        } catch {
            let message: String
            switch error as? ProductValidationError {
            case .emptyName:  message = "请填商品名称"
            default:          message = "分值要为正整数"
            }
            toast.show(.danger, title: message)
            return
        }

        if let product {
            product.name = draft.name
            product.cost = draft.cost
            product.category = draft.category
            product.iconName = draft.iconName
            product.desc = draft.desc
        } else {
            ctx.insert(Product(
                name: draft.name, category: draft.category,
                cost: draft.cost, iconName: draft.iconName, desc: draft.desc
            ))
        }
        try? ctx.save()
        toast.show(.success, title: product == nil ? "已新增「\(draft.name)」" : "已保存「\(draft.name)」",
                   body: "\(draft.cost) 分 · \(draft.category.label)")
        dismiss()
    }

    private struct Field: View {
        @Binding var text: String
        let placeholder: String
        var keyboard: UIKeyboardType = .default
        var body: some View {
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .padding(Spacing.s3)
                .background(Color.kami.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.kami.border, lineWidth: 1)
                )
                .font(.kami(.body, size: 14))
        }
    }
}
