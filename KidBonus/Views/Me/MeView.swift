import SwiftUI
import SwiftData

struct MeView: View {
    @Query private var kids: [Kid]
    @Query private var allItems: [PointItem]
    @Environment(\.modelContext) private var ctx
    @Environment(ToastCenter.self) private var toast
    @State private var showAddItem: Kind?
    @State private var showReset = false

    private var adds: [PointItem] { allItems.filter { $0.kind == .add } }
    private var deds: [PointItem] { allItems.filter { $0.kind == .deduct } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    VStack(alignment: .leading) {
                        Text("我的").font(.kami(.body, size: 28))
                        Text("改名字 · 改积分项 · 重置数据。")
                            .font(.kami(.body, size: 14))
                            .foregroundStyle(Color.kami.muted)
                    }
                    .padding(.horizontal, Spacing.s4)

                    section("01", "两个孩子") {
                        ForEach(kids) { k in
                            HStack {
                                KidAvatar(name: k.name, size: 36, colorHex: k.colorHex)
                                TextField("孩子名字", text: Binding(
                                    get: { k.name },
                                    set: { v in k.name = v; try? ctx.save() }
                                ))
                                .textFieldStyle(.plain)
                                .font(.kami(.body, size: 14))
                                Spacer()
                                Text("\(PointMath.kidPoints(k)) 分")
                                    .font(.kami(.body, size: 12))
                                    .foregroundStyle(Color.kami.meta)
                            }
                            .padding(Spacing.s3)
                            .background(Color.kami.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.md)
                                    .stroke(Color.kami.border, lineWidth: 1)
                            )
                        }
                    }

                    section("02", "加分项") {
                        ForEach(adds) { it in editRow(it) }
                        Button { showAddItem = .add } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("增加加分项")
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.kami.surfaceWarm)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        }
                        .buttonStyle(.plain)
                    }

                    section("03", "扣分项") {
                        ForEach(deds) { it in editRow(it) }
                        Button { showAddItem = .deduct } label: {
                            HStack {
                                Image(systemName: "minus")
                                Text("增加扣分项")
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.kami.surfaceWarm)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        }
                        .buttonStyle(.plain)
                    }

                    section("04", "数据") {
                        Button(role: .destructive) {
                            showReset = true
                        } label: {
                            Text("重置全部数据")
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Color(hex: 0xEFE2DF))
                                .foregroundStyle(Color.kami.danger)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        }
                        .buttonStyle(.plain)
                    }

                    Text("数据保存在本地设备。")
                        .font(.kami(.body, size: 11))
                        .foregroundStyle(Color.kami.meta)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, Spacing.s4)
            }
            .background(Color.kami.bg)
        }
        .sheet(item: $showAddItem) { kind in
            AddItemSheet(kind: kind)
        }
        .confirmationDialog("重置全部数据？此操作不可撤销。",
                            isPresented: $showReset,
                            titleVisibility: .visible) {
            Button("重置", role: .destructive) {
                SeedData.installFresh(ctx: ctx)
                toast.show(.success, title: "已重置", body: "数据已恢复到初始。")
            }
        }
    }

    @ViewBuilder
    private func section<Content: View>(_ num: String, _ label: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            SectionHeader(num: num, label: label)
            VStack(spacing: Spacing.s2) {
                content()
            }
        }
        .padding(.horizontal, Spacing.s4)
    }

    private func editRow(_ it: PointItem) -> some View {
        HStack {
            Text(it.title).font(.kami(.body, size: 13))
            Spacer()
            Text("\(it.delta > 0 ? "+" : "")\(it.delta)")
                .font(.kami(.body, size: 14))
                .foregroundStyle(it.delta > 0 ? Color.kami.success : Color.kami.danger)
            Button(role: .destructive) {
                ctx.delete(it)
                try? ctx.save()
            } label: {
                Image(systemName: "trash").foregroundStyle(Color.kami.danger)
            }
        }
        .padding(.horizontal, Spacing.s3)
        .padding(.vertical, Spacing.s2)
        .background(Color.kami.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md).stroke(Color.kami.border, lineWidth: 1)
        )
    }
}
