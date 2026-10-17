import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var kids: [Kid]
    @Query(sort: \Product.cost, order: .reverse) private var products: [Product]
    @Environment(\.modelContext) private var ctx
    @Environment(ToastCenter.self) private var toast

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        Text("今天，\n两个小家伙的积分")
                            .font(.kami(.body, size: 28))
                        Text("点一下孩子的卡片，开始加减分。")
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
                                bonusActive: streak(for: kid) >= 7
                            ) {
                                toast.show(.info, title: "切换到「加减」tab")
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.s4)

                    SectionHeader(num: "02", label: "快捷加减")
                        .padding(.horizontal, Spacing.s4)

                    HStack(spacing: Spacing.s2) {
                        KamiButton("加分", systemImage: "plus", style: .primary) {
                            toast.show(.info, title: "切换到「加减」tab")
                        }
                        KamiButton("扣分", systemImage: "minus", style: .secondary) {
                            toast.show(.info, title: "切换到「加减」tab")
                        }
                    }
                    .padding(.horizontal, Spacing.s4)

                    SectionHeader(num: "03", label: "推荐商品")
                        .padding(.horizontal, Spacing.s4)

                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: Spacing.s3) {
                        ForEach(products.prefix(4)) { p in
                            ProductCard(product: p, affordable: bestPoints >= p.cost, bestPoints: bestPoints) {}
                        }
                    }
                    .padding(.horizontal, Spacing.s4)
                }
                .padding(.vertical, Spacing.s4)
            }
            .background(Color.kami.bg)
        }
    }

    private var bestPoints: Int {
        kids.map { PointMath.kidPoints($0) }.max() ?? 0
    }

    private func streak(for kid: Kid) -> Int {
        StreakEngine.currentStreak(kidID: kid.id, ctx: ctx)?.count ?? 0
    }

    private var todayLabel: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f.string(from: .now)
    }
}
