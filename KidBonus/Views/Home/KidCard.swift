import SwiftUI
import SwiftData

struct KidCard: View {
    let kid: Kid
    let points: Int
    let today: Int
    /// 当前最长的一次「连续坚持」有多少天
    let streak: Int
    /// 连续天数属于哪个项目，文字里带出来
    let streakLabel: String
    let bonusActive: Bool
    /// bonus 状态的说明文字，随规则和孩子而变
    let bonusLabel: String
    /// 常用积分项，点一下直接记分
    let recentItems: [PointItem]
    /// 点卡片其它位置：打开记分卡片
    let onTap: () -> Void
    /// 点大积分数：直接设定这个孩子的总积分
    let onSetPoints: () -> Void
    /// 点常用项：直接给这个孩子记上
    let onPickItem: (PointItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Button(action: onTap) {
                HStack(spacing: Spacing.s3) {
                    KidAvatar(name: kid.name, size: 44, colorHex: kid.colorHex)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(kid.name).font(.kami(.body, size: 17))
                        Text("\(kid.age) 岁")
                            .font(.kami(.body, size: 11))
                            .foregroundStyle(Color.kami.meta)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.kamiPress)

            Button(action: onSetPoints) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(points)")
                        .font(.kami(.body, size: 36))
                        .foregroundStyle(Color.kami.accent)
                    Text("积分")
                        .font(.kami(.body, size: 13))
                        .foregroundStyle(Color.kami.meta)
                }
            }
            .buttonStyle(.kamiPress)
            .accessibilityIdentifier("kid.points")

            Button(action: onTap) {
                HStack(spacing: Spacing.s4) {
                    statBlock(value: "\(today >= 0 ? "+" : "")\(today)",
                               label: "今日",
                               color: today >= 0 ? Color.kami.success : Color.kami.danger)
                    statBlock(value: "\(streak)", label: streakLabel)
                    statBlock(value: bonusActive ? "★" : "·",
                               label: bonusLabel,
                               color: bonusActive ? Color.kami.warn : Color.kami.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Spacing.s3)
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.kami.borderSoft).frame(height: 1)
                        .offset(y: -Spacing.s3)
                }
            }
            .buttonStyle(.kamiPress)

            if !recentItems.isEmpty {
                recentRow
                    .padding(.top, Spacing.s3)
                    .overlay(alignment: .top) {
                        Rectangle().fill(Color.kami.borderSoft).frame(height: 1)
                            .offset(y: -Spacing.s3)
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(Color.kami.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.kami.border, lineWidth: 1)
        )
    }

    private func statBlock(value: String, label: String, color: Color = .kami.fg) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.kami(.body, size: 15)).foregroundStyle(color)
            Text(label).font(.kami(.body, size: 11)).foregroundStyle(Color.kami.meta)
        }
    }

    /// 常用项：横向一排小按钮，点一下直接给这个孩子记上。
    private var recentRow: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text("最近常用")
                .font(.kami(.body, size: 11))
                .foregroundStyle(Color.kami.meta)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s2) {
                    ForEach(recentItems) { item in
                        Button { onPickItem(item) } label: {
                            HStack(spacing: Spacing.s1) {
                                Image(systemName: item.iconName ?? "circle")
                                    .font(.system(size: 12))
                                Text(item.title).font(.kami(.body, size: 12))
                                Text("\(item.delta > 0 ? "+" : "")\(item.delta)")
                                    .font(.kami(.body, size: 12))
                                    .foregroundStyle(item.delta > 0 ? Color.kami.success : Color.kami.danger)
                            }
                            .foregroundStyle(Color.kami.fg)
                            .padding(.horizontal, Spacing.s3)
                            .padding(.vertical, Spacing.s2)
                            .background(Color.kami.surfaceWarm)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.kamiPress)
                        .accessibilityIdentifier("recent.\(item.title)")
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
}
