import SwiftUI
import SwiftData

struct KidCard: View {
    let kid: Kid
    let points: Int
    let today: Int
    let streak: Int
    let bonusActive: Bool
    /// 点卡片其它位置：打开记分卡片
    let onTap: () -> Void
    /// 点大积分数：直接设定这个孩子的总积分
    let onSetPoints: () -> Void

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
            .buttonStyle(.plain)

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
            .buttonStyle(.plain)
            .accessibilityIdentifier("kid.points")

            Button(action: onTap) {
                HStack(spacing: Spacing.s4) {
                    statBlock(value: "\(today >= 0 ? "+" : "")\(today)",
                               label: "今日",
                               color: today >= 0 ? Color.kami.success : Color.kami.danger)
                    statBlock(value: "\(streak)", label: "连续天数")
                    statBlock(value: bonusActive ? "★" : "·",
                               label: bonusActive ? "bonus 激活" : "bonus 待解锁",
                               color: bonusActive ? Color.kami.warn : Color.kami.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Spacing.s3)
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.kami.borderSoft).frame(height: 1)
                        .offset(y: -Spacing.s3)
                }
            }
            .buttonStyle(.plain)
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
}
