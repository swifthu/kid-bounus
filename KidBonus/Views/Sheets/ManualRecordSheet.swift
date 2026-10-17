import SwiftUI
import SwiftData

struct ManualRecordSheet: View {
    @Query private var kids: [Kid]
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
            let recents = recentFreeforms()
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
                get: { pickedKidID ?? UUID(uuidString: currentKidID) ?? kids.first?.id ?? UUID() },
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
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { toast.show(.danger, title: "请填标题"); return }
        guard var n = Int(deltaText), n != 0 else {
            toast.show(.danger, title: "分值要为非零整数"); return
        }
        n = abs(n)
        if !isAdd { n = -n }
        let picked = pickedKidID ?? UUID(uuidString: currentKidID)
        guard let id = picked, let kid = kids.first(where: { $0.id == id }) else { return }
        let final = note.isEmpty ? t : "\(t)（\(note)）"
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

    private func reuse(_ rf: FreeformChip) {
        guard let id = pickedKidID ?? UUID(uuidString: currentKidID),
              let kid = kids.first(where: { $0.id == id }) else { return }
        _ = RecordStore.recordFreeform(title: rf.title, delta: rf.delta, on: kid, ctx: ctx)
        toast.show(.success, title: "\(kid.name) · \(rf.title)",
                   body: "\(rf.delta > 0 ? "+" : "")\(rf.delta) 分")
        dismiss()
    }

    private struct FreeformChip: Identifiable {
        let id: String
        let title: String
        let delta: Int
    }

    private func recentFreeforms() -> [FreeformChip] {
        var seen: [String: FreeformChip] = [:]
        for h in allHistory {
            let key = h.title + "||" + String(h.delta)
            if seen[key] == nil { seen[key] = FreeformChip(id: key, title: h.title, delta: h.delta) }
        }
        return Array(seen.values.prefix(5))
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
