import SwiftUI
import SwiftData

struct AddItemSheet: View {
    let kind: Kind
    @Query private var kids: [Kid]
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toast
    @AppStorage("currentKidID") private var currentKidID: String = ""
    @State private var scopeTag: String = ""
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
            ScopeTabs(scopes: scopes, selected: effectiveTag) { scopeTag = $0 }

            Field(text: $title, placeholder: "项目名称，如：刷牙早晚")
            Field(text: $deltaText, placeholder: "分值（整数）", keyboard: .numberPad)
            Field(text: $desc, placeholder: "一句说明（可选）")
        }
    }

    struct Scope: Identifiable {
        let tag: String
        let label: String
        var id: String { tag }
    }

    /// 系统分段控件在这套暖色主题下是灰底色块，与 KidTabs 的观感不一致，
    /// 这里按 KidTabs 的画法自绘。
    private struct ScopeTabs: View {
        let scopes: [Scope]
        let selected: String
        let onSelect: (String) -> Void

        var body: some View {
            HStack(spacing: Spacing.s2) {
                ForEach(scopes) { s in
                    Button { onSelect(s.tag) } label: {
                        Text(s.label)
                            .font(.kami(.body, size: 14))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(s.tag == selected ? Color.kami.bg : Color.clear)
                            .foregroundStyle(s.tag == selected ? Color.kami.accent : Color.kami.muted)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.sm)
                                    .stroke(Color.kami.accent, lineWidth: s.tag == selected ? 1 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Spacing.s1)
            .background(Color.kami.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(Color.kami.border, lineWidth: 1)
            )
        }
    }

    private var scopes: [Scope] {
        [Scope(tag: ItemFilter.allKidsTag, label: "通用")] + kids.map {
            Scope(tag: $0.id.uuidString, label: $0.name)
        }
    }

    /// 默认归属当前选中的孩子，回退到第一个孩子；都没有时退回通用。
    private var defaultTag: String {
        KidPicker.resolve(storedID: currentKidID, availableIDs: kids.map(\.id))
            .map { $0.uuidString }
            ?? kids.first.map { $0.id.uuidString }
            ?? ItemFilter.allKidsTag
    }

    /// 保存时读同一个值：用户不碰选择器时存进去的归属要和界面上显示的一致。
    private var effectiveTag: String {
        scopeTag.isEmpty ? defaultTag : scopeTag
    }

    private var selectedKidID: UUID? {
        effectiveTag == ItemFilter.allKidsTag ? nil : UUID(uuidString: effectiveTag)
    }

    private func save() {
        let draft: ItemDraft
        do {
            draft = try ItemValidator.validate(
                kind: kind, kidID: selectedKidID,
                title: title, deltaText: deltaText, descText: desc
            )
        } catch {
            let message: String
            switch error as? ItemValidationError {
            case .emptyTitle: message = "请填名称"
            default:          message = "分值要为非零整数"
            }
            toast.show(.danger, title: message)
            return
        }
        let item = PointItem(
            kind: kind, title: draft.title, delta: draft.delta,
            iconName: ItemValidator.defaultIconName(for: kind),
            desc: draft.desc, kidID: draft.kidID
        )
        ctx.insert(item)
        try? ctx.save()
        let owner = draft.kidID.flatMap { id in kids.first { $0.id == id }?.name } ?? "通用"
        toast.show(.success, title: "已新增「\(draft.title)」",
                   body: "\(draft.delta > 0 ? "+" : "")\(draft.delta) 分 · \(owner)")
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
