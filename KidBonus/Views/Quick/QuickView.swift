import SwiftUI
import SwiftData

struct QuickView: View {
    // 按名字排序：不排序的话 @Query 的顺序不稳定，两个孩子会换位置
    @Query(sort: \Kid.name) private var kids: [Kid]
    @Query private var allItems: [PointItem]
    @Environment(\.modelContext) private var ctx
    @Environment(ToastCenter.self) private var toast
    @AppStorage("currentKidID") private var currentKidID: String = ""
    @State private var showManual = false
    @State private var router = AppRouter.shared

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
                    .buttonStyle(.kamiPress)
                    .padding(.horizontal, Spacing.s4)
                }
                .padding(.vertical, Spacing.s4)
            }
            .background(Color.kami.bg)
        }
        .sheet(isPresented: $showManual) {
            ManualRecordSheet()
        }
        .onAppear { handlePending() }
        .onChange(of: router.pending) { _, _ in handlePending() }
    }

    /// 主屏长按图标的「记一笔」：冷启动时请求在视图出现前就写好了，
    /// 所以 appear 和 change 两条路都要接住。
    private func handlePending() {
        guard router.pending == .manual else { return }
        router.pending = nil
        showManual = true
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
        RecordActions.record(item, on: kid, ctx: ctx, toast: toast)
    }
}

#Preview { QuickView() }
