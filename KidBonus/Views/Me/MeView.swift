import SwiftUI
import SwiftData

struct MeView: View {
    // 按名字排序：不排序的话 @Query 的顺序不稳定，两个孩子会换位置
    @Query(sort: \Kid.name) private var kids: [Kid]
    @Query private var allItems: [PointItem]
    @Query(sort: \BonusRule.days) private var rules: [BonusRule]
    @Environment(\.modelContext) private var ctx
    @Environment(ToastCenter.self) private var toast
    @State private var itemSheet: ItemSheet?
    @State private var ruleSheet: RuleSheet?
    @State private var showReset = false

    /// 新增和编辑共用一个弹层：编辑时传已有项目，界面预填内容。
    private enum ItemSheet: Identifiable {
        case add(Kind)
        case edit(PointItem)

        var id: String {
            switch self {
            case .add(let kind): return "add-\(kind.rawValue)"
            case .edit(let item): return "edit-\(item.id.uuidString)"
            }
        }
    }

    /// bonus 规则同样复用「新增 / 编辑」一个弹层。
    private enum RuleSheet: Identifiable {
        case create
        case edit(BonusRule)

        var id: String {
            switch self {
            case .create: return "create"
            case .edit(let r): return "edit-\(r.id.uuidString)"
            }
        }

        var rule: BonusRule? {
            if case .edit(let r) = self { return r }
            return nil
        }
    }

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
                        Button { itemSheet = .add(.add) } label: {
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
                        Button { itemSheet = .add(.deduct) } label: {
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

                    section("04", "bonus 规则") {
                        if rules.isEmpty {
                            Text("还没有规则，加一条试试。")
                                .font(.kami(.body, size: 12))
                                .foregroundStyle(Color.kami.meta)
                                .padding(Spacing.s3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.kami.surface)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        } else {
                            ForEach(rules) { r in ruleRow(r) }
                        }
                        Button { ruleSheet = .create } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("增加规则")
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.kami.surfaceWarm)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        }
                        .buttonStyle(.plain)
                    }

                    section("05", "数据") {
                        Button(role: .destructive) {
                            showReset = true
                        } label: {
                            Text("重置全部数据")
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Color.kami.dangerBg)
                                .foregroundStyle(Color.kami.danger)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        }
                        .buttonStyle(.plain)
                    }

                    Text("数据保存在本地设备。")
                        .font(.kami(.body, size: 11))
                        .foregroundStyle(Color.kami.meta)
                        .frame(maxWidth: .infinity)

                    Text("字体：霞鹜文楷 LXGW WenKai · SIL OFL 1.1")
                        .font(.kami(.body, size: 11))
                        .foregroundStyle(Color.kami.meta)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, Spacing.s4)
                }
                .padding(.vertical, Spacing.s4)
            }
            .background(Color.kami.bg)
        }
        .sheet(item: $itemSheet) { target in
            switch target {
            case .add(let kind): AddItemSheet(kind: kind, item: nil)
            case .edit(let item): AddItemSheet(kind: item.kind, item: item)
            }
        }
        .sheet(item: $ruleSheet) { target in
            BonusRuleSheet(rule: target.rule)
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

    /// 归属孩子名；kidID 为 nil（通用）或指向已删除的孩子时都显示「通用」。
    private func ownerName(_ kidID: UUID?) -> String {
        guard let kidID, let kid = kids.first(where: { $0.id == kidID }) else { return "通用" }
        return kid.name
    }

    /// 点列表里的项目：打开编辑弹层，预填原有内容
    private func edit(_ it: PointItem) {
        itemSheet = .edit(it)
    }

    /// 一条 bonus 规则：左边说明文字，右边开关 + 编辑 + 删除。
    private func ruleRow(_ r: BonusRule) -> some View {
        HStack(spacing: Spacing.s2) {
            Button { ruleSheet = .edit(r) } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("连续 \(r.days) 天")
                        .font(.kami(.body, size: 13))
                    Text(r.enabled ? "已启用" : "已停用")
                        .font(.kami(.body, size: 11))
                        .foregroundStyle(Color.kami.meta)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("rule.\(r.days)")
            Spacer()
            Text("+\(r.points) 分")
                .font(.kami(.body, size: 14))
                .foregroundStyle(Color.kami.warn)
            Toggle("启用这条规则", isOn: Binding(
                get: { r.enabled },
                set: { v in r.enabled = v; try? ctx.save() }
            ))
            .labelsHidden()
            .tint(Color.kami.accent)
            Button { ruleSheet = .edit(r) } label: {
                Image(systemName: "pencil").foregroundStyle(Color.kami.muted)
            }
            .buttonStyle(.plain)
            Button(role: .destructive) {
                ctx.delete(r)
                try? ctx.save()
                toast.show(.success, title: "已删除规则", body: "连续 \(r.days) 天 +\(r.points) 分")
            } label: {
                Image(systemName: "trash").foregroundStyle(Color.kami.danger)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.s3)
        .padding(.vertical, Spacing.s2)
        .background(Color.kami.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md).stroke(Color.kami.border, lineWidth: 1)
        )
    }

    private func editRow(_ it: PointItem) -> some View {
        HStack(spacing: Spacing.s2) {
            Button { edit(it) } label: {
                Text(it.title).font(.kami(.body, size: 13))
            }
            .buttonStyle(.plain)
            Spacer()
            Tag(text: ownerName(it.kidID), kind: .faint)
                .accessibilityIdentifier("item.owner.\(it.title)")
            Text("\(it.delta > 0 ? "+" : "")\(it.delta)")
                .font(.kami(.body, size: 14))
                .foregroundStyle(it.delta > 0 ? Color.kami.success : Color.kami.danger)
            Button { edit(it) } label: {
                Image(systemName: "pencil").foregroundStyle(Color.kami.muted)
            }
            .buttonStyle(.plain)
            Button(role: .destructive) {
                ctx.delete(it)
                try? ctx.save()
            } label: {
                Image(systemName: "trash").foregroundStyle(Color.kami.danger)
            }
            .buttonStyle(.plain)
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
