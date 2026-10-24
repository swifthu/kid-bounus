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
    /// 加分项 / 扣分项的折叠状态。项目多了以后一屏塞不下，默认展开。
    @State private var addsExpanded = true
    @State private var dedsExpanded = true

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
                        Text("积分项：长按编辑，左滑删除。")
                            .font(.kami(.body, size: 12))
                            .foregroundStyle(Color.kami.meta)
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

                    CollapsibleSection(num: "02", label: "加分项", expanded: $addsExpanded) {
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
                        .buttonStyle(.kamiPress)
                    }

                    CollapsibleSection(num: "03", label: "扣分项", expanded: $dedsExpanded) {
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
                        .buttonStyle(.kamiPress)
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
                        .buttonStyle(.kamiPress)
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
                        .buttonStyle(.kamiPress)
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

    /// 一条 bonus 规则：规则挂在某个加分项上，
    /// 「在这个项目上连续 N 天」就额外奖励 M 分。
    private func ruleRow(_ r: BonusRule) -> some View {
        HStack(spacing: Spacing.s2) {
            Button { ruleSheet = .edit(r) } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(itemTitle(for: r))
                        .font(.kami(.body, size: 13))
                    Text("连续 \(r.days) 天 · \(r.enabled ? "+\(r.points) 分" : "已停用")")
                        .font(.kami(.body, size: 11))
                        .foregroundStyle(r.enabled ? Color.kami.warn : Color.kami.meta)
                }
            }
            .buttonStyle(.kamiPress)
            .accessibilityIdentifier("rule.\(r.days)")
            Spacer()
            Toggle("启用这条规则", isOn: Binding(
                get: { r.enabled },
                set: { v in r.enabled = v; try? ctx.save() }
            ))
            .labelsHidden()
            .tint(Color.kami.accent)
            Button { ruleSheet = .edit(r) } label: {
                Image(systemName: "pencil").foregroundStyle(Color.kami.muted)
            }
            .buttonStyle(.kamiPress)
            Button(role: .destructive) {
                ctx.delete(r)
                try? ctx.save()
                toast.show(.success, title: "已删除规则",
                           body: "\(itemTitle(for: r)) 连续 \(r.days) 天 +\(r.points) 分")
            } label: {
                Image(systemName: "trash").foregroundStyle(Color.kami.danger)
            }
            .buttonStyle(.kamiPress)
        }
        .padding(.horizontal, Spacing.s3)
        .padding(.vertical, Spacing.s2)
        .background(Color.kami.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md).stroke(Color.kami.border, lineWidth: 1)
        )
    }

    /// 规则对应的加分项名字。项目被删了的话说明一下。
    private func itemTitle(for r: BonusRule) -> String {
        guard let itemID = r.itemID,
              let item = allItems.first(where: { $0.id == itemID }) else { return "（项目已删除）" }
        return item.title
    }

    /// 删掉加分项时，连带删掉挂在它上面的奖励规则和连续天数，
    /// 免得留下指向不存在项目的规则。
    private func removeItem(_ it: PointItem) {
        let rules = (try? ctx.fetch(FetchDescriptor<BonusRule>())) ?? []
        for rule in rules where rule.itemID == it.id {
            ctx.delete(rule)
        }
        let streaks = (try? ctx.fetch(FetchDescriptor<Streak>())) ?? []
        for streak in streaks where streak.itemID == it.id {
            ctx.delete(streak)
        }
        ctx.delete(it)
        try? ctx.save()
        toast.show(.success, title: "已删除「\(it.title)」")
    }

    /// 一条积分项：长按编辑，左滑露出删除。轻点不做任何事，避免和左滑的手势打架。
    /// 尺寸和「加减」页的 ItemRow 保持一致，两边看着是同一种东西。
    private func editRow(_ it: PointItem) -> some View {
        SwipeToDelete {
            removeItem(it)
        } content: {
            HStack(spacing: Spacing.s3) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .fill(it.delta > 0 ? Color.kami.tagBgSoft : Color.kami.dangerBg)
                        .frame(width: 36, height: 36)
                    Image(systemName: it.iconName ?? "circle")
                        .foregroundStyle(it.delta > 0 ? Color.kami.accent : Color.kami.danger)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(it.title).font(.kami(.body, size: 14))
                    Text(ownerName(it.kidID))
                        .font(.kami(.body, size: 11))
                        .foregroundStyle(Color.kami.meta)
                }
                Spacer()
                Text("\(it.delta > 0 ? "+" : "")\(it.delta)")
                    .font(.kami(.body, size: 18))
                    .foregroundStyle(it.delta > 0 ? Color.kami.success : Color.kami.danger)
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.vertical, Spacing.s3)
            .background(Color.kami.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md).stroke(Color.kami.border, lineWidth: 1)
            )
            .frame(minHeight: 56)
            .contentShape(RoundedRectangle(cornerRadius: Radius.md))
            .onLongPressGesture { edit(it) }
            // 合并成单个无障碍元素：不然 identifier 会落到图标、标题、分值每一个子元素上，
            // VoiceOver 会读四遍，测试也会匹配到四个元素。
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("item.\(it.title)")
            .accessibilityLabel("\(it.title)，\(ownerName(it.kidID))，"
                                + "\(it.delta > 0 ? "加" : "扣") \(abs(it.delta)) 分")
            .accessibilityAddTraits(.isButton)
            // VoiceOver 没有长按和左滑，双击就是编辑
            .accessibilityHint("双击编辑")
            .accessibilityAction { edit(it) }
        }
    }
}

/// 可折叠的区块：标题整行可点，收起时下面的内容不占地方。
private struct CollapsibleSection<Content: View>: View {
    let num: String
    let label: String
    @Binding var expanded: Bool
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack {
                    SectionHeader(num: num, label: label)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.kami.meta)
                }
                // Spacer 是不画东西的透明区域，SwiftUI 默认只响应「画出来的部分」。
                // 不加这句，点标题中间会穿透到下面的积分项，误开编辑弹层。
                .contentShape(Rectangle())
            }
            .buttonStyle(.kamiPress)
            .accessibilityIdentifier("section.toggle.\(num)")
            .accessibilityLabel("\(label)列表")
            .accessibilityHint(expanded ? "双击折叠" : "双击展开")

            if expanded {
                VStack(spacing: Spacing.s2) {
                    content
                }
            }
        }
        .padding(.horizontal, Spacing.s4)
    }
}
