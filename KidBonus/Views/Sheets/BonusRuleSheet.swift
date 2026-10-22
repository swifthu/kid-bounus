import SwiftUI
import SwiftData

/// bonus 规则的新增 / 编辑表单。`rule` 为 nil 时是新增。
/// 规则针对某个具体的加分项：在这个项目上连续坚持 N 天，就额外奖励 M 分。
struct BonusRuleSheet: View {
    let rule: BonusRule?
    @Query(sort: \PointItem.title) private var allItems: [PointItem]
    // 按名字排序：不排序的话 @Query 的顺序不稳定，两个孩子会换位置
    @Query(sort: \Kid.name) private var kids: [Kid]
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toast
    @State private var itemID: UUID?
    @State private var daysText: String = ""
    @State private var pointsText: String = ""
    @State private var enabled: Bool = true
    @State private var loaded = false

    private var isEditing: Bool { rule != nil }

    /// 可选的项目：只有加分项能算「坚持」。
    struct Target: Identifiable {
        let id: UUID
        let label: String
    }

    var body: some View {
        SheetScaffold(
            title: isEditing ? "编辑规则" : "新增规则",
            message: "选一个加分项，在它上面连续每满 N 天，就额外奖励 M 分。",
            actions: [
                SheetAction(title: "取消", primary: false) { dismiss() },
                SheetAction(title: "保存", primary: true) { save() }
            ]
        ) {
            if targets.isEmpty {
                Text("还没有加分项，先去「加分项」里加一个。")
                    .font(.kami(.body, size: 12))
                    .foregroundStyle(Color.kami.meta)
                    .padding(Spacing.s3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.kami.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            } else {
                Picker("项目", selection: $itemID) {
                    Text("请选择项目").tag(UUID?.none)
                    ForEach(targets) { t in
                        Text(t.label).tag(UUID?.some(t.id))
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
            }

            Field(text: $daysText, placeholder: "连续天数，如：7", keyboard: .numberPad)
            Field(text: $pointsText, placeholder: "奖励分数，如：10", keyboard: .numberPad)

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

    /// 可选项目列表，按归属孩子分组显示，免得同名项目分不清。
    private var targets: [Target] {
        allItems
            .filter { $0.kind == .add }
            .map { Target(id: $0.id, label: "\(ownerName($0.kidID)) · \($0.title)") }
    }

    private func ownerName(_ kidID: UUID?) -> String {
        guard let kidID, let kid = kids.first(where: { $0.id == kidID }) else { return "通用" }
        return kid.name
    }

    /// 表单只在弹层出现时回填一次，避免用户输入后被刷新覆盖。
    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        itemID = rule?.itemID ?? targets.first?.id
        guard let rule else { return }
        daysText = "\(rule.days)"
        pointsText = "\(rule.points)"
        enabled = rule.enabled
    }

    private func save() {
        guard let itemID else {
            toast.show(.danger, title: "请选择项目")
            return
        }
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

        // 同一个项目、同一个周期只能有一条规则，否则连续满 N 天会同时发两份奖
        if BonusRules.hasRule(days: draft.days, itemID: itemID, excluding: rule?.id, ctx: ctx) {
            toast.show(.danger, title: "这个项目已经有连续 \(draft.days) 天的规则了")
            return
        }

        if let rule {
            rule.itemID = itemID
            rule.days = draft.days
            rule.points = draft.points
            rule.enabled = enabled
        } else {
            ctx.insert(BonusRule(itemID: itemID, days: draft.days, points: draft.points, enabled: enabled))
        }
        try? ctx.save()
        let name = allItems.first { $0.id == itemID }?.title ?? ""
        toast.show(.success,
                   title: isEditing ? "已更新规则" : "已新增规则",
                   body: "\(name) 连续每满 \(draft.days) 天 +\(draft.points) 分")
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
