import SwiftUI

struct ItemRow: View {
    let item: PointItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.s3) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .fill(item.delta > 0 ? Color.kami.tagBgSoft : Color.kami.dangerBg)
                        .frame(width: 36, height: 36)
                    Image(systemName: item.iconName ?? "circle")
                        .foregroundStyle(item.delta > 0 ? Color.kami.accent : Color.kami.danger)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title).font(.kami(.body, size: 14))
                    Text(item.desc).font(.kami(.body, size: 11)).foregroundStyle(Color.kami.meta)
                }
                Spacer()
                Text("\(item.delta > 0 ? "+" : "")\(item.delta)")
                    .font(.kami(.body, size: 18))
                    .foregroundStyle(item.delta > 0 ? Color.kami.success : Color.kami.danger)
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.vertical, Spacing.s3)
            .background(Color.kami.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md).stroke(Color.kami.border, lineWidth: 1)
            )
            .frame(minHeight: 56)
        }
        .buttonStyle(.plain)
    }
}
