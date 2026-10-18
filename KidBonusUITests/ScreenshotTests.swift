import XCTest

/// 逐个 tab 截图，用于人工核对 6 个页面的渲染结果。
/// 截图写到 /tmp/kb_shots/ 下，不进仓库。
final class ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    private func snap(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)

        let dir = URL(fileURLWithPath: "/tmp/kb_shots", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? app.screenshot().pngRepresentation.write(to: dir.appendingPathComponent("\(name).png"))
    }

    func testCaptureAllTabs() {
        for tab in ["首页", "加减", "商城", "历程", "我的"] {
            let button = app.tabBars.buttons[tab]
            XCTAssertTrue(button.waitForExistence(timeout: 10), "找不到 tab: \(tab)")
            button.tap()
            snap("tab-\(tab)")
        }

        // 顶部栏的统计入口
        app.tabBars.buttons["首页"].tap()
        let chartButton = app.buttons.matching(identifier: "chart.bar").firstMatch
        if chartButton.exists {
            chartButton.tap()
            snap("sheet-统计")
        }
    }
}
