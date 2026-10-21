import SwiftUI
import SwiftData

struct RedeemConfirmSheet: View {
    let product: Product
    let onClose: () -> Void
    // 按名字排序：不排序的话 @Query 的顺序不稳定，两个孩子会换位置
    @Query(sort: \Kid.name) private var kids: [Kid]
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
                get: { selectedKidID ?? defaultKidID },
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

            transitionCard
        }
    }

    /// 兑换前后分数对照，如「1000 → 800」。积分不足时改为提示还差多少。
    private var transitionCard: some View {
        VStack(spacing: 4) {
            Text(affordable
                 ? PointMath.redeemTransition(points: pointsBefore, cost: product.cost)
                 : "还差 \(ShopFilter.shortfall(product, points: pointsBefore)) 分")
                .font(.kami(.body, size: 20))
                .foregroundStyle(affordable ? Color.kami.accent : Color.kami.danger)
            Text(affordable ? "兑换后剩余分数" : "当前 \(pointsBefore) 分")
                .font(.kami(.body, size: 11))
                .foregroundStyle(Color.kami.meta)
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity)
        .background(Color.kami.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    private var selectedKid: Kid? {
        guard let id = selectedKidID ?? defaultKidID else { return nil }
        return kids.first { $0.id == id }
    }

    private var pointsBefore: Int {
        selectedKid.map(PointMath.kidPoints) ?? 0
    }

    private var affordable: Bool {
        ShopFilter.isAffordable(product, points: pointsBefore)
    }

    /// 必须经 KidPicker 校验：currentKidID 可能是「重置数据」后遗留的旧 UUID，
    /// 能解析但已不对应任何 Kid。此时直接用 UUID(uuidString:) 会静默失灵。
    private var defaultKidID: UUID? {
        KidPicker.resolve(storedID: currentKidID, availableIDs: kids.map(\.id))
    }

    private func confirm() {
        guard let id = selectedKidID ?? defaultKidID,
              let kid = kids.first(where: { $0.id == id }) else {
            toast.show(.danger, title: "没有可用的孩子")
            onClose()
            return
        }
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
