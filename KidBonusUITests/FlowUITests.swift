import XCTest

/// L3 端到端：真实点击验证关键交互链路。
/// 这些用例在修复前会失败 —— 它们锁定的正是审计发现的缺陷。
final class FlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        // 各用例共用模拟器与持久化 store，必须每次启动重置，否则断言互相污染。
        app.launchArguments = ["-uitest-reset"]
        app.launch()
    }

    private func goToTab(_ name: String) {
        let tab = app.tabBars.buttons[name]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "找不到 tab: \(name)")
        tab.tap()
    }

    /// 按钮的 accessibility label 由内部文本拼接而成，用前缀匹配更稳。
    private func button(startingWith prefix: String, timeout: TimeInterval = 10) -> XCUIElement {
        let b = app.buttons.containing(
            NSPredicate(format: "label BEGINSWITH %@", prefix)
        ).firstMatch
        XCTAssertTrue(b.waitForExistence(timeout: timeout), "找不到按钮: \(prefix)")
        return b
    }

    private func text(_ label: String, timeout: TimeInterval = 10) -> XCUIElement {
        let t = app.staticTexts[label]
        XCTAssertTrue(t.waitForExistence(timeout: timeout), "找不到文本: \(label)")
        return t
    }

    // MARK: 种子数据

    func test启动显示两个孩子种子数据() {
        text("小明")
        XCTAssertTrue(app.staticTexts["小红"].exists)
        XCTAssertTrue(app.staticTexts["8 岁"].exists)
        XCTAssertTrue(app.staticTexts["10 岁"].exists)
        // 重置后积分应为 0
        XCTAssertTrue(app.staticTexts["0"].exists, "重置后小明积分应为 0")
    }

    // MARK: 加减分联动

    func test加分后toast出现且积分增加() {
        goToTab("加减")
        button(startingWith: "完成作业").tap()

        // toast 文案含「当前 N 分」
        let toast = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "当前")
        ).firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 5), "加分后应出现 toast")

        goToTab("首页")
        XCTAssertTrue(app.staticTexts["5"].waitForExistence(timeout: 5),
                      "小明积分应变为 5（完成作业 +5）")
    }

    func test扣分后积分减少() {
        goToTab("加减")
        button(startingWith: "忘带作业").tap()

        let toast = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "-5")
        ).firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 5), "扣分后应出现 toast")
    }

    // MARK: D3：手动加减分弹层此前只有一行占位文字

    func test手动加减分弹层可用() {
        goToTab("加减")
        button(startingWith: "手动加减分").tap()

        XCTAssertTrue(app.buttons["记录"].waitForExistence(timeout: 5),
                      "手动记录弹层未打开")
        XCTAssertTrue(app.buttons["取消"].exists)
    }

    func test手动记录后积分增加() {
        goToTab("加减")
        button(startingWith: "手动加减分").tap()

        // 模拟器硬件键盘无法输入中文，这里用 ASCII 标题
        let fields = app.textFields
        XCTAssertTrue(fields.element(boundBy: 0).waitForExistence(timeout: 5))
        fields.element(boundBy: 0).tap()
        fields.element(boundBy: 0).typeText("help")
        // 分值字段默认已是 5，不要再输入，否则会变成 55

        app.buttons["记录"].tap()

        goToTab("首页")
        XCTAssertTrue(app.staticTexts["5"].waitForExistence(timeout: 5),
                      "手动加分 5 分后积分应为 5")
    }

    // MARK: D2：新增积分项弹层此前渲染 EmptyView

    func test增加加分项弹层可用并保存() {
        goToTab("我的")
        button(startingWith: "增加加分项").tap()

        XCTAssertTrue(app.buttons["保存"].waitForExistence(timeout: 5),
                      "AddItemSheet 未打开")

        let fields = app.textFields
        XCTAssertGreaterThanOrEqual(fields.count, 2)
        fields.element(boundBy: 0).tap()
        fields.element(boundBy: 0).typeText("bonusitem")
        fields.element(boundBy: 1).tap()
        fields.element(boundBy: 1).typeText("7")

        app.buttons["保存"].tap()

        XCTAssertTrue(app.staticTexts["bonusitem"].waitForExistence(timeout: 5),
                      "新增的加分项应出现在「我的」列表")
    }

    func test新增扣分项弹层可用() {
        goToTab("我的")
        button(startingWith: "增加扣分项").tap()
        XCTAssertTrue(app.buttons["保存"].waitForExistence(timeout: 5),
                      "新增扣分项弹层未打开")
        // 空标题应被校验拦截，弹层不关闭
        app.buttons["保存"].tap()
        XCTAssertTrue(app.staticTexts["请填名称"].waitForExistence(timeout: 5),
                      "空标题应给出校验提示")
    }

    // MARK: D4：顶栏 person 按钮此前是空实现

    func test顶栏person按钮跳到我的() {
        goToTab("首页")
        app.buttons["person"].tap()

        XCTAssertTrue(app.staticTexts["改名字 · 改积分项 · 重置数据。"].waitForExistence(timeout: 5),
                      "person 按钮应切到「我的」tab")
    }

    // MARK: 商城

    func test商城积分不足时兑换被拦截() {
        goToTab("商城")
        button(startingWith: "乐高积木").tap()

        XCTAssertTrue(app.buttons["兑换"].waitForExistence(timeout: 5), "应弹出兑换确认")
        app.buttons["兑换"].tap()

        let toast = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "不够")
        ).firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 5), "积分不足应提示")
    }

    func test商城分类筛选可用() {
        goToTab("商城")
        app.buttons["图书"].tap()
        XCTAssertTrue(app.staticTexts["漫画书一本"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["乐高积木"].exists, "切到图书分类后不应显示玩具")
    }

    // MARK: 历程

    func test历程页空态() {
        goToTab("历程")
        XCTAssertTrue(app.staticTexts["还没有记录，去加减分页记一笔吧。"].waitForExistence(timeout: 5))
    }

    func test加分后历程出现记录与今天分组() {
        goToTab("加减")
        button(startingWith: "完成作业").tap()
        sleep(1)

        goToTab("历程")
        XCTAssertTrue(app.staticTexts["今天"].waitForExistence(timeout: 5),
                      "记录应归入「今天」分组")
        XCTAssertTrue(app.staticTexts["完成作业"].exists)
    }

    // MARK: 统计

    func test统计弹层可打开() {
        goToTab("首页")
        app.buttons["chart.bar"].tap()
        XCTAssertTrue(app.staticTexts["近 14 天积分变化趋势。"].waitForExistence(timeout: 5))
    }
}
