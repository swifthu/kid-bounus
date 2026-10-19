import SwiftUI
import SwiftData

/// 首页快捷记分弹层：点一项即记分并关闭。
/// `kidID` 为 nil 时顶部提供孩子切换（用于首页的「加分 / 扣分」按钮）；
/// `kind` 为 nil 时同时列加分项与扣分项（用于点头像卡片）。
struct KidQuickPickSheet: View {
    let kidID: UUID?
    let kind: Kind?

    @Query private var kids: [Kid]
    @Query private var allItems: [PointItem]
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toast
    @AppStorage("currentKidID") private var currentKidID: String = ""
    @State private var pickedKidID: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    Text("点一项即记分。")
                        .font(.kami(.body, size: 14))
                        .foregroundStyle(Color.kami.muted)
                        .padding(.horizontal, Spacing.s4)

                    if kidID == nil {
                        KidTabs(kids: kids, selected: Binding(
                            get: { resolvedKidID ?? kids.first?.id ?? UUID() },
                            set: { pickedKidID = $0 }
                        ))
                        .padding(.horizontal, Spacing.s4)
                    }

                    ForEach(kinds) { k in
                        VStack(alignment: .leading, spacing: Spacing.s2) {
                            SectionHeader(num: nil, label: k == .add ? "加分项" : "扣分项")
                            if items(for: k).isEmpty {
                                Text("这个孩子还没有\(k == .add ? "加分" : "扣分")项，去「我的」里添加。")
                                    .font(.kami(.body, size: 12))
                                    .foregroundStyle(Color.kami.meta)
                                    .padding(Spacing.s3)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.kami.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                            } else {
                                VStack(spacing: Spacing.s3) {
                                    ForEach(items(for: k)) { item in
                                        ItemRow(item: item) { record(item) }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.s4)
                    }
                }
                .padding(.vertical, Spacing.s4)
            }
            .background(Color.kami.bg)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private var kinds: [Kind] {
        if let kind { return [kind] }
        return [.add, .deduct]
    }

    /// currentKidID 可能是「重置数据」后遗留的旧 UUID，必须经 KidPicker 回退。
    private var resolvedKidID: UUID? {
        if let kidID { return kidID }
        return pickedKidID ?? KidPicker.resolve(storedID: currentKidID,
                                                availableIDs: kids.map(\.id))
    }

    private var title: String {
        if let kid = kids.first(where: { $0.id == resolvedKidID }) {
            return "给\(kid.name)记分"
        }
        return kind == .deduct ? "扣分" : "加分"
    }

    private func items(for k: Kind) -> [PointItem] {
        ItemFilter.visible(allItems, kidID: resolvedKidID).filter { $0.kind == k }
    }

    private func record(_ item: PointItem) {
        guard let kid = kids.first(where: { $0.id == resolvedKidID }) else {
            toast.show(.danger, title: "没有可用的孩子")
            dismiss()
            return
        }
        let outcome = RecordStore.recordItem(item, on: kid, ctx: ctx)
        toast.show(.success, title: "\(kid.name) · \(item.title)",
                   body: "\(item.delta > 0 ? "+" : "")\(item.delta) 分 · 当前 \(outcome.points) 分")
        if outcome.streakBonus > 0 {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 700_000_000)
                toast.show(.success, title: "\(kid.name) · Streak bonus!",
                           body: "连续 \(outcome.streakCount) 天 · +\(outcome.streakBonus) 分")
            }
        }
        dismiss()
    }
}
