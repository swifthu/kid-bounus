import XCTest
import UIKit
@testable import KidBonus

/// 主屏长按图标的快捷操作：条目和跳转规则。
@MainActor
final class QuickActionTests: XCTestCase {
    func test有三条快捷操作() {
        let items = AppDelegate.makeShortcutItems()
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items.map(\.type),
                       [AppDelegate.quickType, AppDelegate.manualType, AppDelegate.shopType])
        XCTAssertEqual(items.map(\.localizedTitle), ["加减分", "记一笔", "积分商城"])
    }

    func test记一笔会切到加减页并带上手动记录请求() {
        let router = AppRouter.shared
        router.tab = 0
        router.pending = nil

        router.tab = 1
        router.pending = .manual

        XCTAssertEqual(router.tab, 1, "应停在「加减」tab")
        XCTAssertEqual(router.pending, .manual, "应带上打开手动记录的请求")
        router.pending = nil
    }
}
