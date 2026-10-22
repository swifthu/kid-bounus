import SwiftUI
import SwiftData

struct HomeView: View {
    // 按名字排序：不排序的话 @Query 的顺序不稳定，两个孩子会换位置
    @Query(sort: \Kid.name) private var kids: [Kid]
    @Query private var allItems: [PointItem]
    @Query(sort: \BonusRule.days) private var rules: [BonusRule]
    @Environment(\.modelContext) private var ctx
    @Environment(ToastCenter.self) private var toast
    @State private var quickPick: QuickPick? = nil

    /// 首页三个入口共用一个弹层：点头像卡片列全部加减分项，
    /// 点「加分 / 扣分」按钮只列对应的一类，且需要在弹层里选孩子。
    private enum QuickPick: Identifiable {
        case kid(String)
        case setPoints(String)
        case add
        case deduct

        var id: String {
            switch self {
            case .kid(let uuid): return uuid
            case .setPoints(let uuid): return "set-\(uuid)"
            case .add:  return "add"
            case .deduct: return "deduct"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        Text("今天，\n两个小家伙的积分")
                            .font(.kami(.body, size: 28))
                        Text("点卡片记分，点积分数可直接改总分。")
                            .font(.kami(.body, size: 14))
                            .foregroundStyle(Color.kami.muted)
                    }
                    .padding(.horizontal, Spacing.s4)

                    SectionHeader(num: "01", label: todayLabel)
                        .padding(.horizontal, Spacing.s4)

                    VStack(spacing: Spacing.s3) {
                        ForEach(kids) { kid in
                            KidCard(
                                kid: kid,
                                points: PointMath.kidPoints(kid),
                                today: PointMath.todayDelta(kid),
                                streak: streak(for: kid),
                                bonusActive: bonusActive(for: kid),
                                bonusLabel: bonusLabel(for: kid),
                                recentItems: recentItems(for: kid)
                            ) {
                                quickPick = .kid(kid.id.uuidString)
                            } onSetPoints: {
                                quickPick = .setPoints(kid.id.uuidString)
                            } onPickItem: { item in
                                RecordActions.record(item, on: kid, ctx: ctx, toast: toast)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.s4)

                    SectionHeader(num: "02", label: "快捷加减")
                        .padding(.horizontal, Spacing.s4)

                    HStack(spacing: Spacing.s2) {
                        KamiButton("加分", systemImage: "plus", style: .primary) {
                            quickPick = .add
                        }
                        KamiButton("扣分", systemImage: "minus", style: .secondary) {
                            quickPick = .deduct
                        }
                    }
                    .padding(.horizontal, Spacing.s4)
                }
                .padding(.vertical, Spacing.s4)
            }
            .background(Color.kami.bg)
        }
        .sheet(item: $quickPick) { target in
            switch target {
            case .kid(let uuid):
                KidQuickPickSheet(kidID: UUID(uuidString: uuid), kind: nil)
            case .setPoints(let uuid):
                if let kid = kids.first(where: { $0.id.uuidString == uuid }) {
                    SetPointsSheet(kid: kid)
                }
            case .add:
                KidQuickPickSheet(kidID: nil, kind: .add)
            case .deduct:
                KidQuickPickSheet(kidID: nil, kind: .deduct)
            }
        }
    }

    private func streak(for kid: Kid) -> Int {
        StreakEngine.currentStreak(kidID: kid.id, ctx: ctx)?.count ?? 0
    }

    /// 最短的那条启用规则决定 bonus 什么时候解锁，规则是用户自己定的，不能写死 7 天。
    private var firstRuleDays: Int? {
        rules.first(where: { $0.enabled && $0.days > 0 })?.days
    }

    private func bonusActive(for kid: Kid) -> Bool {
        guard let days = firstRuleDays else { return false }
        return streak(for: kid) >= days
    }

    private func bonusLabel(for kid: Kid) -> String {
        guard firstRuleDays != nil else { return "未设规则" }
        return bonusActive(for: kid) ? "bonus 激活" : "bonus 待解锁"
    }

    /// 常用项：这个孩子能看到的、已经用过的项，按用得多的排前面。
    private func recentItems(for kid: Kid) -> [PointItem] {
        ItemFilter.visible(allItems, kidID: kid.id)
            .filter { $0.usageCount > 0 }
            .sorted { lhs, rhs in
                lhs.usageCount == rhs.usageCount
                    ? lhs.title < rhs.title
                    : lhs.usageCount > rhs.usageCount
            }
            .prefix(6)
            .map { $0 }
    }

    private var todayLabel: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f.string(from: .now)
    }
}
