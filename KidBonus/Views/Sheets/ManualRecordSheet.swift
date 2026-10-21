import SwiftUI
import SwiftData

struct ManualRecordSheet: View {
    // 按名字排序：不排序的话 @Query 的顺序不稳定，两个孩子会换位置
    @Query(sort: \Kid.name) private var kids: [Kid]
    @Query(sort: \HistoryRecord.timestamp, order: .reverse) private var allHistory: [HistoryRecord]
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toast
    @AppStorage("currentKidID") private var currentKidID: String = ""
    @State private var title: String = ""
    @State private var deltaText: String = "5"
    @State private var note: String = ""
    @State private var isAdd: Bool = true
    @State private var pickedKidID: UUID?

    var body: some View {
        SheetScaffold(
            title: "手动加减分",
            message: "记一笔临时事项：填写标题和分值，备注可选。不写入预设项。",
            actions: [
                SheetAction(title: "取消", primary: false) { dismiss() },
                SheetAction(title: "记录", primary: true) { save() }
            ]
        ) {
            let recents = FreeformRecents.chips(from: allHistory.entries)
            if recents.isEmpty {
                Text("还没有自定义记录")
                    .font(.kami(.body, size: 11))
                    .foregroundStyle(Color.kami.meta)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(recents, id: \.id) { rf in
                        Button { reuse(rf) } label: {
                            Text("\(rf.delta > 0 ? "+" : "")\(rf.delta) · \(rf.title)")
                                .font(.kami(.body, size: 12))
                                .padding(.horizontal, Spacing.s3).padding(.vertical, Spacing.s2)
                                .background(rf.delta > 0
                                            ? Color(hex: 0xE6EDE0)
                                            : Color(hex: 0xEFE2DF))
                                .foregroundStyle(rf.delta > 0 ? Color.kami.success : Color.kami.danger)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            KidTabs(kids: kids, selected: Binding(
                get: { pickedKidID ?? KidPicker.resolve(storedID: currentKidID, availableIDs: kids.map(\.id)) ?? kids.first?.id ?? UUID() },
                set: { pickedKidID = $0 }
            ))

            Field(text: $title, placeholder: "这次是因为……（必填）")

            HStack(spacing: Spacing.s2) {
                Button { isAdd.toggle() } label: {
                    Text(isAdd ? "+" : "−")
                        .frame(width: 44, height: 44)
                        .background(Color.kami.surfaceWarm)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                }
                .buttonStyle(.plain)
                TextField("分值", text: $deltaText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding(Spacing.s3)
                    .background(Color.kami.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .stroke(Color.kami.border, lineWidth: 1)
                    )
                    .frame(maxWidth: .infinity)
                Text("分").font(.kami(.body, size: 14)).foregroundStyle(Color.kami.meta)
            }

            Field(text: $note, placeholder: "备注（可选）")
        }
    }

    private func save() {
        let draft: ItemDraft
        do {
            draft = try ItemValidator.validate(
                kind: isAdd ? .add : .deduct,
                title: title,
                deltaText: deltaText,
                descText: note
            )
        } catch {
            toast.show(.danger, title: validationToastTitle)
            return
        }
        let n = draft.delta
        guard let kid = resolveKid() else {
            toast.show(.danger, title: "没有可用的孩子")
            return
        }
        let final = note.isEmpty ? draft.title : "\(draft.title)（\(note)）"
        let outcome = RecordStore.recordFreeform(title: final, delta: n, on: kid, ctx: ctx)
        toast.show(.success, title: "\(kid.name) · \(final)",
                   body: "\(n > 0 ? "+" : "")\(n) 分 · 当前 \(outcome.points) 分")
        if outcome.streakBonus > 0 {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 700_000_000)
                toast.show(.success, title: "\(kid.name) · Streak bonus!",
                           body: "连续 \(outcome.streakCount) 天 · +\(outcome.streakBonus) 分")
            }
        }
        dismiss()
    }

    private var validationToastTitle: String {
        title.trimmingCharacters(in: .whitespaces).isEmpty ? "请填标题" : "分值要为非零整数"
    }

    /// currentKidID 可能是「重置数据」后遗留的旧 UUID，能解析但已无对应 Kid，
    /// 必须经 KidPicker 回退，否则会静默失灵。
    private func resolveKid() -> Kid? {
        let id = pickedKidID ?? KidPicker.resolve(storedID: currentKidID,
                                                  availableIDs: kids.map(\.id))
        guard let id else { return nil }
        return kids.first { $0.id == id }
    }

    private func reuse(_ rf: FreeformChip) {
        guard let kid = resolveKid() else { return }
        _ = RecordStore.recordFreeform(title: rf.title, delta: rf.delta, on: kid, ctx: ctx)
        toast.show(.success, title: "\(kid.name) · \(rf.title)",
                   body: "\(rf.delta > 0 ? "+" : "")\(rf.delta) 分")
        dismiss()
    }

    private struct Field: View {
        @Binding var text: String
        let placeholder: String
        var body: some View {
            TextField(placeholder, text: $text)
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

/// Simple FlowLayout (SwiftUI iOS 18+ Layout protocol)
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0
                y += rowH + spacing
                rowH = 0
            }
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowH + spacing
                rowH = 0
            }
            sv.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
    }
}
