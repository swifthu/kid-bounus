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

    /// 点输入框后要等键盘真的弹出来，否则偶发 "no keyboard focus" 输不进字。
    private func focus(_ field: XCUIElement) {
        for _ in 0..<3 {
            field.tap()
            if app.keyboards.firstMatch.waitForExistence(timeout: 2) { return }
        }
        XCTFail("键盘没有弹出，无法输入")
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

    // MARK: 首页快捷记分

    /// 此前首页三个入口只弹一句「切换到加减 tab」的提示，什么也做不了。
    func test首页加分按钮弹层可记分() {
        goToTab("首页")
        button(startingWith: "加分").tap()

        XCTAssertTrue(app.staticTexts["加分项"].waitForExistence(timeout: 5), "应弹出加分项列表")
        XCTAssertFalse(app.staticTexts["扣分项"].exists, "加分入口不应列出扣分项")

        button(startingWith: "完成作业").tap()

        let toast = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "当前 5 分")
        ).firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 5), "记分后应提示当前积分")
    }

    func test首页扣分按钮弹层只列扣分项() {
        goToTab("首页")
        button(startingWith: "扣分").tap()

        XCTAssertTrue(app.staticTexts["扣分项"].waitForExistence(timeout: 5), "应弹出扣分项列表")
        XCTAssertFalse(app.staticTexts["加分项"].exists, "扣分入口不应列出加分项")
    }

    func test首页点头像卡片弹层列全部加减分项() {
        goToTab("首页")
        button(startingWith: "小明").tap()

        XCTAssertTrue(app.staticTexts["加分项"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["扣分项"].exists, "点头像卡片应同时列出加分项与扣分项")
        XCTAssertTrue(app.staticTexts["给小明记分"].exists, "弹层标题应指明是给谁记分")
    }

    // MARK: 加减分联动

    /// 首页不再承载商城内容，商品只在「商城」页出现。
    func test首页不含推荐商品() {
        goToTab("首页")
        XCTAssertFalse(app.staticTexts["推荐商品"].exists, "首页不应再有推荐商品区块")
        XCTAssertFalse(app.staticTexts["乐高积木"].exists, "首页不应出现商品卡片")
    }

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

    /// 兑换前要能看清扣多少分、扣完还剩多少分。
    func test兑换确认显示兑换前后分数() {
        // 七个种子加分项共 32 分，够换 25 分的贴纸
        goToTab("加减")
        for name in ["完成作业", "阅读 30 分", "整理房间", "帮忙家务",
                     "运动 30 分", "刷牙早晚", "主动练琴"] {
            button(startingWith: name).tap()
        }

        goToTab("商城")
        button(startingWith: "贴纸一包").tap()

        XCTAssertTrue(app.buttons["兑换"].waitForExistence(timeout: 5), "应弹出兑换确认")
        let transition = app.staticTexts.containing(
            NSPredicate(format: "label MATCHES %@", "[0-9]+ → [0-9]+")
        ).firstMatch
        XCTAssertTrue(transition.waitForExistence(timeout: 5),
                      "确认弹层应显示「兑换前 → 兑换后」的分数")
        XCTAssertEqual(transition.label, "32 → 7")
    }

    func test商品管理页可打开并新增商品() {
        goToTab("商城")
        let manage = app.buttons["shop.manage"]
        XCTAssertTrue(manage.waitForExistence(timeout: 5), "商城页应有商品管理入口")
        manage.tap()

        XCTAssertTrue(app.staticTexts["商品管理"].waitForExistence(timeout: 5))
        button(startingWith: "新增商品").tap()

        let fields = app.textFields
        focus(fields.element(boundBy: 0))
        fields.element(boundBy: 0).typeText("giftbox")
        focus(fields.element(boundBy: 1))
        fields.element(boundBy: 1).typeText("120")

        app.buttons["保存"].tap()

        XCTAssertTrue(app.staticTexts["giftbox"].waitForExistence(timeout: 5),
                      "新增的商品应出现在管理列表")
    }

    func test商品管理页可删除商品() {
        goToTab("商城")
        app.buttons["shop.manage"].tap()
        XCTAssertTrue(app.staticTexts["乐高积木"].waitForExistence(timeout: 5))

        // 列表按分值从高到低排，第一行就是乐高积木；删除按钮的 label 取 SF Symbol 名。
        let del = app.buttons["trash"].firstMatch
        XCTAssertTrue(del.waitForExistence(timeout: 5), "管理列表每行都应有删除按钮")
        del.tap()

        XCTAssertFalse(app.staticTexts["乐高积木"].waitForExistence(timeout: 2),
                       "删除后该商品应从列表消失")
    }

    /// 新增的加分项只归属一个孩子，换孩子后不该再出现。
    func test加减分项按归属孩子过滤() {
        goToTab("我的")
        button(startingWith: "增加加分项").tap()
        XCTAssertTrue(app.buttons["保存"].waitForExistence(timeout: 5), "AddItemSheet 未打开")

        // 分段选择器的每一段在无障碍树里就是普通按钮
        let red = app.buttons["小红"]
        XCTAssertTrue(red.waitForExistence(timeout: 5), "新增弹层应能选择归属孩子")
        red.tap()
        print("=== TAPPED RED ===")
        let sheetTexts = app.staticTexts.allElementsBoundByIndex.map { $0.label }
        print(sheetTexts)

        let fields = app.textFields
        focus(fields.element(boundBy: 0))
        fields.element(boundBy: 0).typeText("kidonly")
        focus(fields.element(boundBy: 1))
        fields.element(boundBy: 1).typeText("7")
        app.buttons["保存"].tap()

        XCTAssertTrue(app.staticTexts["kidonly"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["item.owner.kidonly"].label, "小红",
                       "选了小红的项应归属于小红")

        // 加减页显式切到小明再断言：默认选中哪个孩子会受上一次运行残留的
        // currentKidID 影响，这里要验的是过滤本身。
        goToTab("加减")
        button(startingWith: "小明").tap()
        XCTAssertFalse(app.staticTexts["kidonly"].waitForExistence(timeout: 2),
                       "归属小红的项不应出现在小明的列表里")

        button(startingWith: "小红").tap()
        XCTAssertTrue(app.staticTexts["kidonly"].waitForExistence(timeout: 5),
                      "切到小红后应能看到归属她的项")
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

    /// 右滑露出删除按钮，删掉后积分要回调。
    func test历程右滑删除并回调积分() {
        goToTab("加减")
        button(startingWith: "完成作业").tap()   // +5
        sleep(1)

        goToTab("历程")
        XCTAssertTrue(app.staticTexts["完成作业"].waitForExistence(timeout: 5))

        let row = app.staticTexts["完成作业"]
        // 标题文本很窄，要拖到 dx 2.5 才够拉开删除按钮
        let start = row.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        let end = row.coordinate(withNormalizedOffset: CGVector(dx: 2.5, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end)

        let del = app.buttons["删除"]
        XCTAssertTrue(del.waitForExistence(timeout: 5), "右滑应露出删除按钮")
        del.tap()

        // toast 只显示 2.4 秒，必须先查它，再做会耗时 2 秒的存在性断言
        let toast = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "回调 5 分")
        ).firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 5), "应提示回调了多少分")
        XCTAssertFalse(app.staticTexts["完成作业"].waitForExistence(timeout: 2),
                       "删除后该记录应消失")

        goToTab("首页")
        XCTAssertTrue(app.staticTexts["0"].waitForExistence(timeout: 5),
                      "删掉 +5 后积分应回到 0")
    }

    // MARK: 统计

    func test统计弹层可打开() {
        goToTab("首页")
        app.buttons["chart.bar"].tap()
        XCTAssertTrue(app.staticTexts["近 14 天积分变化趋势。"].waitForExistence(timeout: 5))
    }
}
