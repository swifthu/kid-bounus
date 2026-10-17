import SwiftUI
import SwiftData

struct ShopView: View {
    @Query private var products: [Product]
    @Query private var kids: [Kid]
    @Query(sort: \Redemption.timestamp, order: .reverse) private var redemptions: [Redemption]
    @State private var cat: ProductCategory? = nil
    @State private var pending: Product? = nil
    @Environment(\.modelContext) private var ctx
    @Environment(ToastCenter.self) private var toast

    private static let cats: [ProductCategory?] = [nil, .toy, .book, .food, .priv, .out]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("积分商城").font(.kami(.body, size: 28))
                        Text("点击商品兑换。不足会标灰。")
                            .font(.kami(.body, size: 14))
                            .foregroundStyle(Color.kami.muted)
                    }
                    .padding(.horizontal, Spacing.s4)

                    HStack(spacing: Spacing.s2) {
                        ForEach(Self.cats, id: \.self) { c in
                            chip(c?.label ?? "全部", selected: c == cat) { cat = c }
                        }
                    }
                    .padding(.horizontal, Spacing.s4)

                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: Spacing.s3) {
                        ForEach(filtered) { p in
                            ProductCard(
                                product: p,
                                affordable: bestPoints >= p.cost,
                                bestPoints: bestPoints
                            ) { pending = p }
                        }
                    }
                    .padding(.horizontal, Spacing.s4)

                    SectionHeader(num: nil, label: "兑换记录")
                    if redemptions.isEmpty {
                        Text("还没有兑换记录。")
                            .font(.kami(.body, size: 12))
                            .foregroundStyle(Color.kami.meta)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.kami.surface)
                            .padding(.horizontal, Spacing.s4)
                    } else {
                        VStack(spacing: Spacing.s2) {
                            ForEach(redemptions.prefix(10)) { r in redemptionRow(r) }
                        }
                        .padding(.horizontal, Spacing.s4)
                    }
                }
                .padding(.vertical, Spacing.s4)
            }
            .background(Color.kami.bg)
        }
        .sheet(isPresented: Binding(
            get: { pending != nil },
            set: { if !$0 { pending = nil } }
        )) {
            if let p = pending {
                RedeemConfirmSheet(product: p) { pending = nil }
            }
        }
    }

    private var bestPoints: Int {
        kids.map { PointMath.kidPoints($0) }.max() ?? 0
    }

    private var filtered: [Product] {
        let pool = cat == nil ? products : products.filter { $0.category == cat }
        return pool.sorted { $0.cost > $1.cost }
    }

    private func chip(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.kami(.body, size: 13))
                .padding(.horizontal, Spacing.s3)
                .padding(.vertical, Spacing.s2)
                .frame(minHeight: 36)
                .background(selected ? Color.kami.tagBgSoft : Color.kami.surface)
                .foregroundStyle(selected ? Color.kami.accent : Color.kami.muted)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xs))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xs)
                        .stroke(selected ? Color.kami.tagBgSoft : Color.kami.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func redemptionRow(_ r: Redemption) -> some View {
        HStack(spacing: Spacing.s3) {
            Image(systemName: "gift")
                .frame(width: 36, height: 36)
                .background(Color.kami.tagBgSoft)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            VStack(alignment: .leading) {
                Text(r.productName).font(.kami(.body, size: 13))
                Text("\(r.kid?.name ?? "") · \(formatDate(r.timestamp))")
                    .font(.kami(.body, size: 11)).foregroundStyle(Color.kami.meta)
            }
            Spacer()
            Text("-\(r.cost)")
                .font(.kami(.body, size: 14))
                .foregroundStyle(Color.kami.accent)
        }
        .padding(Spacing.s3)
        .background(Color.kami.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md).stroke(Color.kami.border, lineWidth: 1)
        )
    }

    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 HH:mm"
        return f.string(from: d)
    }
}

#Preview { ShopView() }
