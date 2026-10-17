import Foundation

enum PointMath {
    static func kidPoints(_ kid: Kid) -> Int {
        let earned = kid.history.reduce(0) { $0 + $1.delta }
        let spent  = kid.redemptions.reduce(0) { $0 + $1.cost }
        return earned - spent
    }

    static func todayDelta(_ kid: Kid) -> Int {
        let k = DateKey.today
        return kid.history
            .filter { DateKey.day($0.timestamp) == k }
            .reduce(0) { $0 + $1.delta }
    }
}
