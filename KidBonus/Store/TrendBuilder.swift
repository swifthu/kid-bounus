import Foundation

struct TrendBucket: Equatable { var dateKey: String; var value: Int }
struct DistributionRow: Equatable { var title: String; var add: Int; var deduct: Int }

enum TrendBuilder {
    /// Returns N daily buckets from oldest to newest, each containing net points (earned - spent).
    static func trend(_ kid: Kid, days: Int = 14) -> [TrendBucket] {
        var out: [TrendBucket] = []
        for i in stride(from: days - 1, through: 0, by: -1) {
            let key = DateKey.day(before: i)
            let earned = kid.history.filter { DateKey.day($0.timestamp) == key }
                                   .reduce(0) { $0 + $1.delta }
            let spent  = kid.redemptions.filter { DateKey.day($0.timestamp) == key }
                                        .reduce(0) { $0 + $1.cost }
            out.append(TrendBucket(dateKey: key, value: earned - spent))
        }
        return out
    }

    /// Aggregates all history records by title, counting add/deduct separately, sorted by (add - deduct) descending.
    static func distribution(_ kid: Kid) -> [DistributionRow] {
        var tally: [String: (add: Int, deduct: Int)] = [:]
        for h in kid.history {
            var t = tally[h.title] ?? (0, 0)
            if h.delta > 0 { t.add += 1 } else { t.deduct += 1 }
            tally[h.title] = t
        }
        return tally
            .map { DistributionRow(title: $0.key, add: $0.value.add, deduct: $0.value.deduct) }
            .sorted { ($0.add - $0.deduct) > ($1.add - $1.deduct) }
    }
}
