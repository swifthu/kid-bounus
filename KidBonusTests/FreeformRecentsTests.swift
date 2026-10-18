import XCTest
@testable import KidBonus

/// L1 纯逻辑：最近自定义记录的去重与筛选。
final class FreeformRecentsTests: XCTestCase {

    private func entry(_ title: String, _ delta: Int,
                       kind: SourceKind = .freeform) -> HistoryEntry {
        HistoryEntry(id: UUID(), title: title, delta: delta, timestamp: .now,
                     kidID: nil, sourceKind: kind)
    }

    /// 回归 D5：预设项与连续奖励不应出现在「自定义记录」里。
    func test只取freeform记录() {
        let chips = FreeformRecents.chips(from: [
            entry("完成作业", 5, kind: .preset),
            entry("主动帮忙", 4),
            entry("连续 7 天 bonus", 20, kind: .streakBonus),
        ])
        XCTAssertEqual(chips.map(\.title), ["主动帮忙"])
    }

    func test空输入返回空() {
        XCTAssertTrue(FreeformRecents.chips(from: []).isEmpty)
    }

    func test同名不同分值视为不同条目() {
        let chips = FreeformRecents.chips(from: [entry("帮忙", 3), entry("帮忙", -3)])
        XCTAssertEqual(chips.count, 2)
    }

    func test同名同分值去重() {
        let chips = FreeformRecents.chips(from: [
            entry("帮忙", 3), entry("帮忙", 3), entry("练琴", 8),
        ])
        XCTAssertEqual(chips.map(\.title), ["帮忙", "练琴"])
    }

    func test保持传入顺序() {
        let chips = FreeformRecents.chips(from: [entry("A", 1), entry("B", 2), entry("C", 3)])
        XCTAssertEqual(chips.map(\.title), ["A", "B", "C"])
    }

    /// 回归 D6：结果必须稳定，不能依赖 Dictionary 迭代顺序。
    func test重复调用结果稳定() {
        let entries = (1...20).map { entry("项目\($0)", $0) }
        let first = FreeformRecents.chips(from: entries)
        for _ in 0..<20 {
            XCTAssertEqual(FreeformRecents.chips(from: entries), first)
        }
    }

    func test超过上限被截断() {
        let entries = (1...10).map { entry("项目\($0)", $0) }
        XCTAssertEqual(FreeformRecents.chips(from: entries).count, 5)
        XCTAssertEqual(FreeformRecents.chips(from: entries, limit: 3).count, 3)
    }

    func test不足上限时返回全部() {
        XCTAssertEqual(FreeformRecents.chips(from: [entry("A", 1), entry("B", 2)]).count, 2)
    }
}
