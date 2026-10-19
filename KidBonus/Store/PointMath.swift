import Foundation

enum PointMath {
    /// Net points from history records and redemptions.
    /// Accepts explicit arrays so it works in tests without a SwiftData context.
    static func kidPoints(_ history: [HistoryRecord], _ redemptions: [Redemption]) -> Int {
        let earned = history.reduce(0) { $0 + $1.delta }
        let spent  = redemptions.reduce(0) { $0 + $1.cost }
        return earned - spent
    }

    /// Net points for a Kid (uses the object's relationship properties).
    static func kidPoints(_ kid: Kid) -> Int {
        kidPoints(kid.history, kid.redemptions)
    }

    /// Today's net delta from history records.
    /// Accepts explicit array so it works in tests without a SwiftData context.
    static func todayDelta(_ history: [HistoryRecord]) -> Int {
        let k = DateKey.today
        return history
            .filter { DateKey.day($0.timestamp) == k }
            .reduce(0) { $0 + $1.delta }
    }

    /// Today's delta for a Kid (uses the object's relationship property).
    static func todayDelta(_ kid: Kid) -> Int {
        todayDelta(kid.history)
    }

    /// 兑换后剩余积分。积分不足时为负，调用方据此决定是否放行。
    static func afterRedeem(points: Int, cost: Int) -> Int {
        points - cost
    }

    /// 兑换确认弹层里的分数变化文案，如 "1000 → 800"。
    static func redeemTransition(points: Int, cost: Int) -> String {
        "\(points) → \(afterRedeem(points: points, cost: cost))"
    }
}
