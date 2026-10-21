import SwiftUI
import SwiftData

/// 商城商品管理：新增、编辑、删除商品目录。
struct ShopManageView: View {
    @Query(sort: \Product.cost, order: .reverse) private var products: [Product]
    @Environment(\.modelContext) private var ctx
    @Environment(ToastCenter.self) private var toast
    @State private var editor: EditorTarget? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                // 标题用导航栏的，页面里不再重复一遍
                Text("新增、修改分值或删除商品。")
                    .font(.kami(.body, size: 14))
                    .foregroundStyle(Color.kami.muted)
                    .padding(.horizontal, Spacing.s4)

                Button { editor = .create } label: {
                    HStack(spacing: Spacing.s2) {
                        Image(systemName: "plus")
                        Text("新增商品")
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.kami.surfaceWarm)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Spacing.s4)

                if products.isEmpty {
                    Text("还没有商品，点上面新增。")
                        .font(.kami(.body, size: 12))
                        .foregroundStyle(Color.kami.meta)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.kami.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        .padding(.horizontal, Spacing.s4)
                } else {
                    VStack(spacing: Spacing.s2) {
                        ForEach(products) { p in
                            row(p)
                        }
                    }
                    .padding(.horizontal, Spacing.s4)
                }
            }
            .padding(.vertical, Spacing.s4)
        }
        .background(Color.kami.bg)
        .navigationTitle("商品管理")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editor) { target in
            ProductEditSheet(product: target.product)
        }
    }

    private enum EditorTarget: Identifiable {
        case create
        case edit(Product)

        var id: String {
            switch self {
            case .create: return "create"
            case .edit(let p): return p.id.uuidString
            }
        }

        var product: Product? {
            if case .edit(let p) = self { return p }
            return nil
        }
    }

    private func row(_ p: Product) -> some View {
        HStack(spacing: Spacing.s3) {
            Button { editor = .edit(p) } label: {
                HStack(spacing: Spacing.s3) {
                    Image(systemName: p.iconName ?? "gift")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.kami.accent)
                        .frame(width: 36, height: 36)
                        .background(Color.kami.tagBgSoft)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.name).font(.kami(.body, size: 13))
                        Text("\(p.category.label) · \(p.desc)")
                            .font(.kami(.body, size: 11))
                            .foregroundStyle(Color.kami.meta)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Text("\(p.cost) 分")
                .font(.kami(.body, size: 14))
                .foregroundStyle(Color.kami.accent)
            Button { editor = .edit(p) } label: {
                Image(systemName: "pencil").foregroundStyle(Color.kami.muted)
            }
            .buttonStyle(.plain)
            Button(role: .destructive) { remove(p) } label: {
                Image(systemName: "trash").foregroundStyle(Color.kami.danger)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.s3)
        .background(Color.kami.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md).stroke(Color.kami.border, lineWidth: 1)
        )
    }

    private func remove(_ p: Product) {
        ctx.delete(p)
        try? ctx.save()
        toast.show(.success, title: "已删除「\(p.name)」")
    }
}

#Preview { ShopManageView() }
