import SwiftUI
import SwiftData

/// 直接设定某个孩子的总积分。差额会记进历程，方便回溯。
struct SetPointsSheet: View {
    let kid: Kid
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toast
    @State private var valueText: String = ""

    private var current: Int {
        PointMath.kidPoints(kid)
    }

    private var target: Int? {
        Int(valueText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var body: some View {
        SheetScaffold(
            title: "设定\(kid.name)的积分",
            message: "直接设定总积分，差额会记进历程。",
            actions: [
                SheetAction(title: "取消", primary: false) { dismiss() },
                SheetAction(title: "保存", primary: true) { save() }
            ]
        ) {
            HStack {
                Text("当前积分").font(.kami(.body, size: 14))
                Spacer()
                Text("\(current) 分")
                    .font(.kami(.body, size: 14))
                    .foregroundStyle(Color.kami.meta)
            }
            .padding(Spacing.s3)
            .background(Color.kami.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))

            Field(text: $valueText, placeholder: "新的总积分（整数）", keyboard: .numberPad)

            if let target, target != current {
                let diff = target - current
                Text("将变为 \(target) 分（\(diff > 0 ? "+" : "")\(diff)）")
                    .font(.kami(.body, size: 12))
                    .foregroundStyle(Color.kami.meta)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func save() {
        guard let target else {
            toast.show(.danger, title: "请填整数")
            return
        }
        let points = RecordStore.setPoints(target, for: kid, ctx: ctx)
        toast.show(.success, title: "\(kid.name) 的积分已设为 \(target)",
                   body: "当前 \(points) 分")
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
