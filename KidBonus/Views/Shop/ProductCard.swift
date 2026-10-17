import SwiftUI

struct ProductCard: View {
    let product: Product
    let affordable: Bool
    let bestPoints: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                ZStack {
                    Rectangle().fill(affordable ? Color.kami.tagBgSoft : Color.kami.tagBgFaint)
                        .aspectRatio(1, contentMode: .fit)
                    Image(systemName: product.iconName ?? "gift")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.kami.accent)
                }
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(product.name).font(.kami(.body, size: 13))
                    HStack(spacing: 2) {
                        Text("\(product.cost)")
                            .font(.kami(.body, size: 18))
                            .foregroundStyle(Color.kami.accent)
                        Text("分").font(.kami(.body, size: 11)).foregroundStyle(Color.kami.meta)
                    }
                    Tag(text: affordable ? "可兑换" : "还差 \(product.cost - bestPoints)",
                        kind: affordable ? .success : .faint)
                }
                .padding(.horizontal, Spacing.s2)
                .padding(.bottom, Spacing.s3)
            }
            .background(Color.kami.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md).stroke(Color.kami.border, lineWidth: 1)
            )
            .opacity(affordable ? 1 : 0.6)
        }
        .buttonStyle(.plain)
    }
}
