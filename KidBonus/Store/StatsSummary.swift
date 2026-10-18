import Foundation

/// 「统计」页的次数统计。
enum StatsSummary {
    static func positiveCount(_ entries: [HistoryEntry]) -> Int {
        entries.filter { $0.delta > 0 }.count
    }

    static func negativeCount(_ entries: [HistoryEntry]) -> Int {
        entries.filter { $0.delta < 0 }.count
    }
}
