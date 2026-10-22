import Foundation
import SwiftData

/// 删掉一条兑换记录后，撤销要用的数据副本。
struct RedemptionSnapshot: Equatable {
    let kidID: UUID?
    let productName: String
    let cost: Int
    let timestamp: Date

    init(_ redemption: Redemption) {
        kidID = redemption.kid?.id
        productName = redemption.productName
        cost = redemption.cost
        timestamp = redemption.timestamp
    }
}

/// 记录相关的公共逻辑，历程页、商城页和首页共用。
@MainActor
enum RecordActions {
    /// 记一笔预设项，并按需要补一条连续奖励提示。
    static func record(_ item: PointItem, on kid: Kid, ctx: ModelContext, toast: ToastCenter) {
        let outcome = RecordStore.recordItem(item, on: kid, ctx: ctx)
        toast.show(.success, title: "\(kid.name) · \(item.title)",
                   body: "\(item.delta > 0 ? "+" : "")\(item.delta) 分 · 当前 \(outcome.points) 分")
        if outcome.streakBonus > 0 {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 700_000_000)
                toast.show(.success, title: "\(kid.name) · Streak bonus!",
                           body: "连续 \(outcome.streakCount) 天 · +\(outcome.streakBonus) 分")
            }
        }
    }

    static func deleteRecord(_ record: HistoryRecord, ctx: ModelContext, toast: ToastCenter) {
        let snapshot = HistorySnapshot(record)
        let who = record.kid?.name ?? ""
        let points = RecordStore.deleteRecord(record, ctx: ctx)
        toast.show(.success,
                   title: "已删除「\(record.title)」",
                   body: "回调 \(abs(record.delta)) 分 · \(who)当前 \(points) 分",
                   action: .init(title: "撤销") {
                       let back = RecordStore.restore(snapshot, ctx: ctx)
                       toast.show(.info, title: "已恢复「\(record.title)」", body: "当前 \(back) 分")
                   })
    }

    static func deleteRedemption(_ redemption: Redemption, ctx: ModelContext, toast: ToastCenter) {
        let snapshot = RedemptionSnapshot(redemption)
        let who = redemption.kid?.name ?? ""
        let points = RecordStore.deleteRedemption(redemption, ctx: ctx)
        toast.show(.success,
                   title: "已撤销兑换「\(redemption.productName)」",
                   body: "退回 \(redemption.cost) 分 · \(who)当前 \(points) 分",
                   action: .init(title: "撤销") {
                       let back = RecordStore.restoreRedemption(snapshot, ctx: ctx)
                       toast.show(.info,
                                  title: "已恢复兑换「\(redemption.productName)」",
                                  body: "当前 \(back) 分")
                   })
    }
}
