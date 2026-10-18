import XCTest
@testable import KidBonus

final class StatsSummaryTests: XCTestCase {

    private func entry(_ delta: Int) -> HistoryEntry {
        HistoryEntry(id: UUID(), title: "t", delta: delta, timestamp: .now,
                     kidID: nil, sourceKind: .preset)
    }

    func test加分次数() {
        XCTAssertEqual(StatsSummary.positiveCount([entry(5), entry(3), entry(-2)]), 2)
    }

    func test扣分次数() {
        XCTAssertEqual(StatsSummary.negativeCount([entry(5), entry(3), entry(-2)]), 1)
    }

    func test空历史() {
        XCTAssertEqual(StatsSummary.positiveCount([]), 0)
        XCTAssertEqual(StatsSummary.negativeCount([]), 0)
    }

    /// delta 为 0 的记录既不算加分也不算扣分。
    func test零分值不计入任何一侧() {
        XCTAssertEqual(StatsSummary.positiveCount([entry(0)]), 0)
        XCTAssertEqual(StatsSummary.negativeCount([entry(0)]), 0)
    }
}
