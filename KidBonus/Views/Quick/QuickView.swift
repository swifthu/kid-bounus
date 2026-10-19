import SwiftUI
import SwiftData

struct QuickView: View {
    @Query private var kids: [Kid]
    @Query private var allItems: [PointItem]
    @Environment(\.modelContext) private var ctx
    @Environment(ToastCenter.self) private var toast
    @AppStorage("currentKidID") private var currentKidID: String = ""
    @State private var showManual = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        Text("加减分").font(.kami(.body, size: 28))
                        Text("选孩子，再点一项。")
                            .font(.kami(.body, size: 14))
                            .foregroundStyle(Color.kami.muted)
                    }
                    .padding(.horizontal, Spacing.s4)

                    SectionHeader(num: nil, label: "选一个孩子")
                        .padding(.horizontal, Spacing.s4)
                    Group {
                        if !kids.isEmpty {
                            KidTabs(kids: kids, selected: Binding(
                                get: { selectedKidID ?? kids[0].id },
                                set: { currentKidID = $0.uuidString }
                            ))
                        }
                    }
                    .padding(.horizontal, Spacing.s4)

                    SectionHeader(num: nil, label: "加分项")
                        .padding(.horizontal, Spacing.s4)
                    VStack(spacing: Spacing.s3) {
                        ForEach(scopedItems.filter { $0.kind == .add }) { item in
                            ItemRow(item: item) { addOrDeduct(item) }
                        }
                    }
                    .padding(.horizontal, Spacing.s4)

                    SectionHeader(num: nil, label: "扣分项")
                        .padding(.horizontal, Spacing.s4)
                    VStack(spacing: Spacing.s3) {
                        ForEach(scopedItems.filter { $0.kind == .deduct }) { item in
                            ItemRow(item: item) { addOrDeduct(item) }
                        }
                    }
                    .padding(.horizontal, Spacing.s4)

                    SectionHeader(num: nil, label: "自定义加减")
                        .padding(.horizontal, Spacing.s4)
                    Button { showManual = true } label: {
                        HStack(spacing: Spacing.s3) {
                            Image(systemName: "pencil")
                                .frame(width: 36, height: 36)
                                .background(Color.kami.tagBgSoft)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                            VStack(alignment: .leading) {
                                Text("手动加减分").font(.kami(.body, size: 14))
                                Text("自定义标题和分值，不入预设项")
                                    .font(.kami(.body, size: 11)).foregroundStyle(Color.kami.meta)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Color.kami.meta)
                        }
                        .padding(Spacing.s4)
                        .background(Color.kami.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .stroke(Color.kami.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Spacing.s4)
                }
                .padding(.vertical, Spacing.s4)
            }
            .background(Color.kami.bg)
        }
        .sheet(isPresented: $showManual) {
            ManualRecordSheet()
        }
    }

    /// currentKidID 可能是「重置数据」后遗留的旧 UUID，必须经 KidPicker 回退。
    private var selectedKidID: UUID? {
        KidPicker.resolve(storedID: currentKidID, availableIDs: kids.map(\.id))
    }

    private var scopedItems: [PointItem] {
        ItemFilter.visible(allItems, kidID: selectedKidID)
    }

    private func addOrDeduct(_ item: PointItem) {
        guard let kid = kids.first(where: { $0.id.uuidString == currentKidID }) ?? kids.first else { return }
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
    }
}

#Preview { QuickView() }
