import XCTest
@testable import KidBonus

final class DateKeyTests: XCTestCase {

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = d; comps.hour = 12
        return Calendar.current.date(from: comps)!
    }

    func test日期键零填充格式() {
        XCTAssertEqual(DateKey.day(date(2026, 1, 5)), "2026-01-05")
        XCTAssertEqual(DateKey.day(date(2026, 12, 25)), "2026-12-25")
    }

    func test跨月日期正确() {
        XCTAssertEqual(DateKey.day(date(2026, 2, 1)), "2026-02-01")
        XCTAssertNotEqual(DateKey.day(date(2026, 1, 31)), DateKey.day(date(2026, 2, 1)))
    }

    func test跨年日期正确() {
        XCTAssertEqual(DateKey.day(date(2025, 12, 31)), "2025-12-31")
        XCTAssertNotEqual(DateKey.day(date(2025, 12, 31)), DateKey.day(date(2026, 1, 1)))
    }

    func test今天等于当前时刻的键() {
        XCTAssertEqual(DateKey.today, DateKey.day(.now))
    }

    func testbefore零等于今天() {
        XCTAssertEqual(DateKey.day(before: 0), DateKey.today)
    }

    func testbefore递减日期严格不同() {
        let keys = (0...14).map { DateKey.day(before: $0) }
        XCTAssertEqual(Set(keys).count, 15, "14 天窗口内不应出现重复日期键")
    }

    func testbefore跨月() {
        // 取本月 3 号往前推 5 天，落在上个月
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        comps.day = 3; comps.hour = 12
        let third = Calendar.current.date(from: comps)!
        XCTAssertNotEqual(DateKey.day(before: 5), DateKey.day(third))
    }
}
