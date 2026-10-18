import XCTest
@testable import KidBonus

/// L1 纯逻辑：不需要 ModelContainer，全部用值类型 HistoryEntry。
final class HistoryGroupingTests: XCTestCase {

    private func entry(_ title: String, _ delta: Int, _ date: Date,
                       kidID: UUID? = nil, kind: SourceKind = .preset) -> HistoryEntry {
        HistoryEntry(id: UUID(), title: title, delta: delta, timestamp: date,
                     kidID: kidID, sourceKind: kind)
    }

    private func daysAgo(_ n: Int, hour: Int = 10) -> Date {
        let base = Calendar.current.date(byAdding: .day, value: -n, to: .now) ?? .now
        return Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: base) ?? base
    }

    // MARK: 分组

    func test按天分组正确() {
        let entries = [
            entry("a", 5, daysAgo(0)),
            entry("b", 5, daysAgo(0)),
            entry("c", -3, daysAgo(1)),
        ]
        let groups = HistoryGrouping.group(entries)
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0].entries.count, 2)
        XCTAssertEqual(groups[1].entries.count, 1)
    }

    /// 回归 D7：天数必须降序，最近的一天在最前。
    func test天按时间降序排列() {
        let entries = [
            entry("三天前", 5, daysAgo(3)),
            entry("今天", 5, daysAgo(0)),
            entry("昨天", 5, daysAgo(1)),
        ]
        let groups = HistoryGrouping.group(entries)
        XCTAssertEqual(groups.map(\.key), [DateKey.today, DateKey.day(before: 1), DateKey.day(before: 3)])
    }

    func test组内按时间倒序排列() {
        let morning = daysAgo(0, hour: 9)
        let noon = daysAgo(0, hour: 12)
        let evening = daysAgo(0, hour: 20)
        let groups = HistoryGrouping.group([
            entry("早", 5, morning), entry("晚", 5, evening), entry("中", 5, noon),
        ])
        XCTAssertEqual(groups[0].entries.map(\.title), ["晚", "中", "早"])
    }

    func test空输入返回空分组() {
        XCTAssertTrue(HistoryGrouping.group([]).isEmpty)
    }

    // MARK: 标签

    func test今天标签() {
        XCTAssertEqual(HistoryGrouping.label(for: DateKey.today), "今天")
    }

    func test昨天标签() {
        XCTAssertEqual(HistoryGrouping.label(for: DateKey.day(before: 1)), "昨天")
    }

    func test更早的天显示月日() {
        let key = DateKey.day(before: 5)
        let parts = key.split(separator: "-").compactMap { Int($0) }
        XCTAssertEqual(HistoryGrouping.label(for: key), "\(parts[1])月\(parts[2])日")
        XCTAssertNotEqual(HistoryGrouping.label(for: key), "今天")
        XCTAssertNotEqual(HistoryGrouping.label(for: key), "昨天")
    }

    func test跨月标签不含前导零() {
        // 2026-01-05 应显示为「1月5日」而不是「01月05日」
        XCTAssertEqual(HistoryGrouping.label(for: "2026-01-05"), "1月5日")
        XCTAssertEqual(HistoryGrouping.label(for: "2026-12-25"), "12月25日")
    }

    func test无法解析的键原样返回() {
        XCTAssertEqual(HistoryGrouping.label(for: "garbage"), "garbage")
    }

    // MARK: 筛选

    func test按孩子筛选() {
        let k1 = UUID(), k2 = UUID()
        let entries = [
            entry("a", 5, daysAgo(0), kidID: k1),
            entry("b", 5, daysAgo(0), kidID: k2),
        ]
        XCTAssertEqual(HistoryGrouping.filter(entries, kidID: k1).map(\.title), ["a"])
    }

    func testnil表示全部() {
        let entries = [entry("a", 5, daysAgo(0), kidID: UUID())]
        XCTAssertEqual(HistoryGrouping.filter(entries, kidID: nil).count, 1)
    }
}
