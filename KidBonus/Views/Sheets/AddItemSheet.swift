import SwiftUI
import SwiftData

struct AddItemSheet: View {
    let kind: Kind
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toast
    @State private var title: String = ""
    @State private var deltaText: String = ""
    @State private var desc: String = ""

    var body: some View {
        SheetScaffold(
            title: "新增\(kind == .add ? "加分" : "扣分")项",
            actions: [
                SheetAction(title: "取消", primary: false) { dismiss() },
                SheetAction(title: "保存", primary: true) { save() }
            ]
        ) {
            Field(text: $title, placeholder: "项目名称，如：刷牙早晚")
            Field(text: $deltaText, placeholder: "分值（整数）", keyboard: .numberPad)
            Field(text: $desc, placeholder: "一句说明（可选）")
        }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { toast.show(.danger, title: "请填名称"); return }
        guard var d = Int(deltaText), d != 0 else {
            toast.show(.danger, title: "分值要为非零整数"); return
        }
        if kind == .add && d < 0 { d = -d }
        if kind == .deduct && d > 0 { d = -d }
        let item = PointItem(
            kind: kind, title: t, delta: d,
            iconName: kind == .add ? "checkmark" : "exclamationmark",
            desc: desc.isEmpty ? (kind == .add ? "一个好习惯" : "需要改进的小事") : desc
        )
        ctx.insert(item)
        try? ctx.save()
        toast.show(.success, title: "已新增「\(t)」",
                   body: "\(d > 0 ? "+" : "")\(d) 分")
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
