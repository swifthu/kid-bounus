import XCTest
@testable import KidBonus

@MainActor
final class ToastCenterTests: XCTestCase {

    func testShow设置当前toast() {
        let toast = ToastCenter()
        toast.show(.success, title: "小明 · 完成作业", body: "+5 分")
        XCTAssertEqual(toast.current?.title, "小明 · 完成作业")
        XCTAssertEqual(toast.current?.body, "+5 分")
        XCTAssertEqual(toast.current?.kind, .success)
    }

    func test连续show后者覆盖前者() {
        let toast = ToastCenter()
        toast.show(.info, title: "第一条")
        toast.show(.danger, title: "第二条")
        XCTAssertEqual(toast.current?.title, "第二条")
    }

    func test到期后自动清除() async throws {
        let toast = ToastCenter()
        toast.show(.info, title: "x", duration: 0.1)
        XCTAssertNotNil(toast.current)
        try await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertNil(toast.current)
    }

    /// 回归 D1：先发 toast 的定时器不得清除后发的那条。
    /// 修复前 `current?.id == current?.id` 恒真，第一条到期会把第二条一起清掉，
    /// 导致 streak 连续奖励提示只显示约 1.7 秒就被截断。
    func test新toast不被旧定时器提前清除() async throws {
        let toast = ToastCenter()
        toast.show(.info, title: "第一条", duration: 0.2)
        try await Task.sleep(nanoseconds: 50_000_000)
        toast.show(.success, title: "第二条", duration: 1.5)

        // 等到第一条的定时器早已到期（0.2s + 余量）
        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertEqual(toast.current?.title, "第二条",
                       "第一条的定时器不应清除第二条")
    }

    /// 真实的 streak 场景：加分后 700ms 弹出奖励提示，两者应共存到各自到期。
    func test连续奖励提示不被截断() async throws {
        let toast = ToastCenter()
        toast.show(.success, title: "小明 · 完成作业", duration: 0.6)
        try await Task.sleep(nanoseconds: 300_000_000)
        toast.show(.success, title: "Streak bonus!", duration: 1.5)
        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertEqual(toast.current?.title, "Streak bonus!")
    }
}
