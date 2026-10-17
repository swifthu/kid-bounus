import SwiftUI
import SwiftData

struct RedeemConfirmSheet: View {
    let product: Product
    let onClose: () -> Void
    @Query private var kids: [Kid]
    @Environment(\.modelContext) private var ctx
    @Environment(ToastCenter.self) private var toast
    @AppStorage("currentKidID") private var currentKidID: String = ""
    @State private var selectedKidID: UUID?

    var body: some View {
        SheetScaffold(
            title: product.name,
            message: "需要 \(product.cost) 分。\(product.desc)",
            actions: [
                SheetAction(title: "取消", primary: false) { onClose() },
                SheetAction(title: "兑换", primary: true) { confirm() }
            ]
        ) {
            Picker("孩子", selection: Binding(
                get: { selectedKidID ?? defaultKid },
                set: { selectedKidID = $0 }
            )) {
                ForEach(kids) { k in
                    Text("\(k.name) · \(PointMath.kidPoints(k)) 分")
                        .tag(k.id as UUID?)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.kami.accent)
            .padding(Spacing.s3)
            .background(Color.kami.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
    }

    private var defaultKid: UUID? {
        UUID(uuidString: currentKidID) ?? kids.first?.id
    }

    private func confirm() {
        guard let id = selectedKidID ?? defaultKid,
              let kid = kids.first(where: { $0.id == id }) else { return }
        if PointMath.kidPoints(kid) < product.cost {
            toast.show(.danger, title: "积分不足",
                       body: "\(kid.name) 的积分不够。")
            onClose()
            return
        }
        let ok = RecordStore.redeem(product, by: kid, ctx: ctx)
        if ok {
            toast.show(.success, title: "\(kid.name) 兑换了 \(product.name)",
                       body: "剩余 \(PointMath.kidPoints(kid)) 分")
        }
        onClose()
    }
}
