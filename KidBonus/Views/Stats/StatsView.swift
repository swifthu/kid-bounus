import SwiftUI
import SwiftData

struct StatsView: View {
    // 按名字排序：不排序的话 @Query 的顺序不稳定，两个孩子会换位置
    @Query(sort: \Kid.name) private var kids: [Kid]
    @AppStorage("currentKidID") private var currentKidID: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    VStack(alignment: .leading) {
                        Text("统计").font(.kami(.body, size: 28))
                        Text("近 14 天积分变化趋势。")
                            .font(.kami(.body, size: 14))
                            .foregroundStyle(Color.kami.muted)
                    }
                    .padding(.horizontal, Spacing.s4)

                    KidTabs(kids: kids, selected: Binding(
                        // kids 为空时不能 kids[0]，那会越界崩溃
                        get: { KidPicker.resolve(storedID: currentKidID, availableIDs: kids.map(\.id)) ?? kids.first?.id ?? UUID() },
                        set: { currentKidID = $0.uuidString }
                    ))
                    .padding(.horizontal, Spacing.s4)

                    if let kid = currentKid {
                        VStack(alignment: .leading, spacing: Spacing.s4) {
                            HStack(spacing: Spacing.s3) {
                                statBlock(value: "\(PointMath.kidPoints(kid))", label: "当前积分")
                                statBlock(value: "\(StatsSummary.positiveCount(kid.history.entries))", label: "加分次数")
                                statBlock(value: "\(StatsSummary.negativeCount(kid.history.entries))", label: "扣分次数")
                            }
                            .padding(Spacing.s4)
                            .background(Color.kami.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.md)
                                    .stroke(Color.kami.border, lineWidth: 1)
                            )

                            Sparkline(buckets: TrendBuilder.trend(kid))

                            SectionHeader(num: nil, label: "按项目分布")
                            VStack(spacing: Spacing.s2) {
                                ForEach(TrendBuilder.distribution(kid).prefix(8), id: \.title) { r in
                                    HStack {
                                        Text(r.title).font(.kami(.body, size: 14))
                                        Spacer()
                                        Text("+\(r.add) · −\(r.deduct)")
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
                        }
                        .padding(.horizontal, Spacing.s4)
                    }
                }
                .padding(.vertical, Spacing.s4)
            }
            .background(Color.kami.bg)
        }
    }

    private var currentKid: Kid? {
        kids.first { $0.id.uuidString == currentKidID } ?? kids.first
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(alignment: .leading) {
            Text(value).font(.kami(.body, size: 22)).foregroundStyle(Color.kami.fg)
            Text(label).font(.kami(.body, size: 11)).foregroundStyle(Color.kami.meta)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
