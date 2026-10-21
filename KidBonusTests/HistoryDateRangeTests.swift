import XCTest
@testable import KidBonus

/// L1 纯逻辑：历程页的日期区间筛选。
final class HistoryDateRangeTests: XCTestCase {
    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = 12
        return Calendar.current.date(from: c)!
    }

    func test三种区间的标签() {
        XCTAssertEqual(HistoryDateRange.day.label, "当天")
        XCTAssertEqual(HistoryDateRange.week.label, "近7天")
        XCTAssertEqual(HistoryDateRange.month.label, "近30天")
    }

    func test窗口天数() {
        XCTAssertEqual(HistoryDateRange.day.days, 1)
        XCTAssertEqual(HistoryDateRange.week.days, 7)
        XCTAssertEqual(HistoryDateRange.month.days, 30)
    }

    /// 当天窗口就是 anchor 那一天，起点终点相同。
    func test当天窗口() {
        let w = HistoryDateRange.day.window(anchor: date(2026, 8, 21))
        XCTAssertEqual(w.start, "2026-08-21")
        XCTAssertEqual(w.end, "2026-08-21")
    }

    func test近7天窗口含当天往前6天() {
        let w = HistoryDateRange.week.window(anchor: date(2026, 8, 21))
        XCTAssertEqual(w.start, "2026-08-15")
        XCTAssertEqual(w.end, "2026-08-21")
    }

    func test近30天窗口含当天往前29天() {
        let w = HistoryDateRange.month.window(anchor: date(2026, 8, 21))
        XCTAssertEqual(w.start, "2026-07-23")
        XCTAssertEqual(w.end, "2026-08-21")
    }

    func test窗口跨月() {
        let w = HistoryDateRange.week.window(anchor: date(2026, 3, 2))
        XCTAssertEqual(w.start, "2026-02-24")
        XCTAssertEqual(w.end, "2026-03-02")
    }

    func test当天只含那一天() {
        let anchor = date(2026, 8, 21)
        XCTAssertTrue(HistoryDateRange.day.contains(date(2026, 8, 21), anchor: anchor))
        XCTAssertFalse(HistoryDateRange.day.contains(date(2026, 8, 20), anchor: anchor))
        XCTAssertFalse(HistoryDateRange.day.contains(date(2026, 8, 22), anchor: anchor))
    }

    /// 同一天里的不同时间点都算当天。
    func test当天按自然日判断不按时刻() {
        let anchor = date(2026, 8, 21)
        var c = DateComponents()
        c.year = 2026; c.month = 8; c.day = 21; c.hour = 23; c.minute = 59
        let lateNight = Calendar.current.date(from: c)!
        XCTAssertTrue(HistoryDateRange.day.contains(lateNight, anchor: anchor))
    }

    func test近7天含边界两天() {
        let anchor = date(2026, 8, 21)
        XCTAssertTrue(HistoryDateRange.week.contains(date(2026, 8, 15), anchor: anchor))
        XCTAssertTrue(HistoryDateRange.week.contains(date(2026, 8, 21), anchor: anchor))
        XCTAssertFalse(HistoryDateRange.week.contains(date(2026, 8, 14), anchor: anchor))
        XCTAssertFalse(HistoryDateRange.week.contains(date(2026, 8, 22), anchor: anchor))
    }

    func test近30天含边界两天() {
        let anchor = date(2026, 8, 21)
        XCTAssertTrue(HistoryDateRange.month.contains(date(2026, 7, 23), anchor: anchor))
        XCTAssertFalse(HistoryDateRange.month.contains(date(2026, 7, 22), anchor: anchor))
    }

    // MARK: 与孩子筛选叠加

    private func entry(_ kidID: UUID?, _ when: Date) -> HistoryEntry {
        HistoryEntry(id: UUID(), title: "t", delta: 5, timestamp: when,
                     kidID: kidID, sourceKind: .preset)
    }

    func test同时按孩子和日期筛选() {
        let a = UUID()
        let anchor = date(2026, 8, 21)
        let entries = [
            entry(a, date(2026, 8, 21)),
            entry(a, date(2026, 8, 10)),
            entry(nil, date(2026, 8, 21))
        ]

        let got = HistoryGrouping.filter(entries, kidID: a,
                                         dateRange: .day, anchor: anchor)

        XCTAssertEqual(got.count, 1)
        XCTAssertEqual(got.first?.kidID, a)
    }

    func test全部孩子时只按日期筛() {
        let anchor = date(2026, 8, 21)
        let entries = [
            entry(UUID(), date(2026, 8, 21)),
            entry(UUID(), date(2026, 8, 10))
        ]

        let got = HistoryGrouping.filter(entries, kidID: nil,
                                         dateRange: .day, anchor: anchor)

        XCTAssertEqual(got.count, 1)
    }

    func test区间外没有记录时返回空() {
        let anchor = date(2026, 8, 21)
        let entries = [entry(nil, date(2026, 1, 1))]

        XCTAssertTrue(HistoryGrouping.filter(entries, kidID: nil,
                                             dateRange: .month, anchor: anchor).isEmpty)
    }

    func test短日期文案() {
        XCTAssertEqual(HistoryGrouping.shortDate("2026-08-21"), "8月21日")
        XCTAssertEqual(HistoryGrouping.shortDate("2026-01-05"), "1月5日")
        XCTAssertEqual(HistoryGrouping.shortDate("乱码"), "乱码")
    }
}
