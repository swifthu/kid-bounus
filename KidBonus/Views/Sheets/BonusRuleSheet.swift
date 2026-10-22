import SwiftUI
import SwiftData

/// bonus 规则的新增 / 编辑表单。`rule` 为 nil 时是新增。
struct BonusRuleSheet: View {
    let rule: BonusRule?
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toast
    @State private var daysText: String = ""
    @State private var pointsText: String = ""
    @State private var enabled: Bool = true
    @State private var loaded = false

    private var isEditing: Bool { rule != nil }

    var body: some View {
        SheetScaffold(
            title: isEditing ? "编辑规则" : "新增规则",
            message: "连续每满 days 天，就奖励 points 分。",
            actions: [
                SheetAction(title: "取消", primary: false) { dismiss() },
                SheetAction(title: "保存", primary: true) { save() }
            ]
        ) {
            Field(text: $daysText, placeholder: "连续天数，如：7", keyboard: .numberPad)
            Field(text: $pointsText, placeholder: "奖励分数，如：20", keyboard: .numberPad)

            Toggle("启用这条规则", isOn: $enabled)
                .font(.kami(.body, size: 14))
                .tint(Color.kami.accent)
                .padding(Spacing.s3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.kami.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.kami.border, lineWidth: 1)
                )
        }
        .onAppear(perform: loadIfNeeded)
    }

    /// 表单只在弹层出现时回填一次，避免用户输入后被刷新覆盖。
    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        guard let rule else { return }
        daysText = "\(rule.days)"
        pointsText = "\(rule.points)"
        enabled = rule.enabled
    }

    private func save() {
        let draft: BonusRuleDraft
        do {
            draft = try BonusRuleValidator.validate(daysText: daysText, pointsText: pointsText)
        } catch {
            let message: String
            switch error as? BonusRuleValidationError {
            case .emptyDays:     message = "请填连续天数"
            case .invalidDays:   message = "连续天数要大于 0"
            case .emptyPoints:   message = "请填奖励分数"
            default:             message = "奖励分数要大于 0"
            }
            toast.show(.danger, title: message)
            return
        }

        // 同一个周期只能有一条规则，否则连续满 N 天会同时发两份奖
        if BonusRules.hasRule(days: draft.days, excluding: rule?.id, ctx: ctx) {
            toast.show(.danger, title: "已经有连续 \(draft.days) 天的规则了")
            return
        }

        if let rule {
            rule.days = draft.days
            rule.points = draft.points
            rule.enabled = enabled
        } else {
            ctx.insert(BonusRule(days: draft.days, points: draft.points, enabled: enabled))
        }
        try? ctx.save()
        toast.show(.success,
                   title: isEditing ? "已更新规则" : "已新增规则",
                   body: "连续每满 \(draft.days) 天 +\(draft.points) 分")
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
