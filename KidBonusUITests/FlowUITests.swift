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

    /// 清空字段再输入：光标落在哪里不确定，退格清空最稳。
    /// 退格用输入字符的方式（键盘上的 delete 键在弹层里可能被顶到屏幕外，点不到）。
    private func retype(_ field: XCUIElement, _ text: String) {
        focus(field)
        let current = (field.value as? String) ?? ""
        if !current.isEmpty {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        field.typeText(text)
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

    /// 点首页大积分数 → 弹窗直接设定这个孩子的总积分。
    func test首页点积分数可设定积分() {
        goToTab("加减")
        button(startingWith: "完成作业").tap()   // +5
        sleep(1)

        goToTab("首页")
        // 大积分数：第一个孩子（小明）的那块
        let points = app.buttons["kid.points"].firstMatch
        XCTAssertTrue(points.waitForExistence(timeout: 5), "首页应有大积分数可点")
        points.tap()

        XCTAssertTrue(app.buttons["保存"].waitForExistence(timeout: 5), "应弹出设定积分弹层")
        XCTAssertTrue(app.staticTexts["设定小明的积分"].waitForExistence(timeout: 5),
                      "弹层标题应指明是给谁设定积分")

        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        focus(field)
        field.typeText("100")

        app.buttons["保存"].tap()

        // toast 只显示 2.4 秒，必须先查它
        let toast = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "积分已设为 100")
        ).firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 5), "应提示设定结果")

        XCTAssertTrue(app.staticTexts["100"].waitForExistence(timeout: 5),
                      "首页大积分数应变为 100")
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

        XCTAssertTrue(app.buttons["bonusitem"].waitForExistence(timeout: 5),
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

    /// 「我的」页点积分项：打开新增同款弹层，预填原有内容，改完保存。
    func test我的页积分项可编辑() {
        goToTab("我的")
        // 列表里点「完成作业」这一项（标题本身可点，进了编辑弹层）
        let title = app.buttons["完成作业"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()

        XCTAssertTrue(app.buttons["保存"].waitForExistence(timeout: 5), "应打开编辑弹层")
        let sheetTitle = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "编辑加分项")
        ).firstMatch
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 5), "标题应是「编辑加分项」")

        // 预填：名称和分值都在
        let fields = app.textFields
        XCTAssertTrue(fields.element(boundBy: 0).waitForExistence(timeout: 5))
        XCTAssertEqual(fields.element(boundBy: 0).value as? String, "完成作业")
        XCTAssertEqual(fields.element(boundBy: 1).value as? String, "5")

        // 改名字
        retype(fields.element(boundBy: 0), "改名作业")
        app.buttons["保存"].tap()

        XCTAssertTrue(app.buttons["改名作业"].waitForExistence(timeout: 5),
                      "列表应显示新名字")
    }

    /// 商城管理页点商品名：打开新增同款弹层，预填原有内容。
    func test商城管理页商品可编辑() {
        goToTab("商城")
        app.buttons["shop.manage"].tap()
        XCTAssertTrue(app.staticTexts["乐高积木"].waitForExistence(timeout: 5))

        app.staticTexts["乐高积木"].tap()

        XCTAssertTrue(app.buttons["保存"].waitForExistence(timeout: 5), "应打开编辑弹层")
        let fields = app.textFields
        XCTAssertTrue(fields.element(boundBy: 0).waitForExistence(timeout: 5))
        XCTAssertEqual(fields.element(boundBy: 0).value as? String, "乐高积木")
        XCTAssertEqual(fields.element(boundBy: 1).value as? String, "200")

        // 改名字（数字键盘没有可用的退格键，名称用普通键盘改）
        retype(fields.element(boundBy: 0), "新积木")
        app.buttons["保存"].tap()

        XCTAssertTrue(app.staticTexts["新积木"].waitForExistence(timeout: 5),
                      "列表应显示改后的名字")
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

        XCTAssertTrue(app.buttons["kidonly"].waitForExistence(timeout: 5))
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

    /// 日期筛选控件：可展开折叠，展开后有当天/近7天/近30天三个按钮。
    func test历程日期筛选可展开折叠() {
        goToTab("历程")

        let toggle = button(startingWith: "日期筛选")
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "应有日期筛选入口")
        XCTAssertFalse(app.buttons["近7天"].exists, "默认折叠时不显示区间按钮")

        toggle.tap()
        XCTAssertTrue(app.buttons["当天"].waitForExistence(timeout: 5), "展开后应出现区间按钮")
        XCTAssertTrue(app.buttons["近7天"].exists)
        XCTAssertTrue(app.buttons["近30天"].exists)

        app.buttons["近7天"].tap()
        toggle.tap()
        XCTAssertFalse(app.buttons["近7天"].exists, "收起后区间按钮应隐藏")
    }

    /// 标题里不再有「按天分组，最近 30 天」那行说明。
    func test历程页不再有旧副标题() {
        goToTab("历程")
        XCTAssertTrue(app.staticTexts["历程"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["按天分组，最近 30 天。"].exists)
    }

    /// 切到「当天」后，今天的记录还在；切到别的日期就没有记录了。
    func test历程按当天筛选() {
        goToTab("加减")
        button(startingWith: "完成作业").tap()
        sleep(1)

        goToTab("历程")
        XCTAssertTrue(app.staticTexts["完成作业"].waitForExistence(timeout: 5))

        button(startingWith: "日期筛选").tap()
        app.buttons["当天"].tap()
        XCTAssertTrue(app.staticTexts["完成作业"].waitForExistence(timeout: 5),
                      "今天的记录应在当天区间内")
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

    /// 在某一行上向左拖，拖过按钮宽度的一半才会展开删除按钮。
    /// 从元素本身的坐标出发不可靠（标题文本很窄），这里用整屏坐标从行右侧往左拖。
    private func swipeLeft(on element: XCUIElement) {
        let appFrame = app.frame
        let y = element.frame.midY / appFrame.height
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: y))
        let end = app.coordinate(
            withNormalizedOffset: CGVector(dx: 0.9 - 180 / appFrame.width, dy: y)
        )
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    /// 左滑露出删除按钮，删掉后积分要回调。
    func test历程左滑删除并回调积分() {
        goToTab("加减")
        button(startingWith: "完成作业").tap()   // +5
        sleep(1)

        goToTab("历程")
        XCTAssertTrue(app.staticTexts["完成作业"].waitForExistence(timeout: 5))

        swipeLeft(on: app.staticTexts["完成作业"])

        let del = app.buttons["删除"]
        XCTAssertTrue(del.waitForExistence(timeout: 5), "左滑应露出删除按钮")
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

    /// 删错了能反悔：toast 上的「撤销」把记录要回来。
    func test删除后可以撤销() {
        goToTab("加减")
        button(startingWith: "完成作业").tap()   // +5
        sleep(1)

        goToTab("历程")
        XCTAssertTrue(app.staticTexts["完成作业"].waitForExistence(timeout: 5))

        swipeLeft(on: app.staticTexts["完成作业"])
        let del = app.buttons["删除"]
        XCTAssertTrue(del.waitForExistence(timeout: 5), "左滑应露出删除按钮")
        del.tap()

        let undo = app.buttons["撤销"]
        XCTAssertTrue(undo.waitForExistence(timeout: 5), "删除后应给出撤销入口")
        undo.tap()

        XCTAssertTrue(app.staticTexts["完成作业"].waitForExistence(timeout: 5),
                      "撤销后记录应回到列表")
    }

    /// 商城里的兑换记录也能左滑撤销，分数要退回来。
    func test商城兑换记录可左滑撤销() {
        // 先攒够 25 分，贴纸一包要 25 分
        goToTab("加减")
        for _ in 0..<5 {
            button(startingWith: "完成作业").tap()
            sleep(1)
        }

        goToTab("商城")
        button(startingWith: "贴纸一包").tap()
        XCTAssertTrue(app.buttons["兑换"].waitForExistence(timeout: 5))
        app.buttons["兑换"].tap()
        sleep(1)

        let row = app.staticTexts["redemption.贴纸一包"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "兑换记录应出现在商城页")
        swipeLeft(on: row)

        let del = app.buttons["删除"]
        XCTAssertTrue(del.waitForExistence(timeout: 5), "左滑应露出删除按钮")
        del.tap()

        let undo = app.buttons["撤销"]
        XCTAssertTrue(undo.waitForExistence(timeout: 5), "撤销兑换后应有撤销入口")
    }

    // MARK: bonus 规则

    /// 「我的」页可以自定义 bonus 规则：在某个项目上连续几天发多少分。
    func test我的页可新增bonus规则() {
        goToTab("我的")
        button(startingWith: "增加规则").tap()

        XCTAssertTrue(app.buttons["保存"].waitForExistence(timeout: 5), "规则弹层未打开")
        let fields = app.textFields
        XCTAssertGreaterThanOrEqual(fields.count, 2)
        fields.element(boundBy: 0).tap()
        fields.element(boundBy: 0).typeText("3")
        fields.element(boundBy: 1).tap()
        fields.element(boundBy: 1).typeText("15")

        app.buttons["保存"].tap()

        XCTAssertTrue(app.staticTexts["连续 3 天 · +15 分"].waitForExistence(timeout: 5),
                      "新规则应出现在列表里")
    }

    /// 规则是挂在某个加分项上的：换一个项目，同一个周期可以再有一条规则。
    func test同一项目同一周期不能建两条规则() {
        goToTab("我的")
        button(startingWith: "增加规则").tap()
        XCTAssertTrue(app.buttons["保存"].waitForExistence(timeout: 5))

        let fields = app.textFields
        fields.element(boundBy: 0).tap()
        fields.element(boundBy: 0).typeText("3")
        fields.element(boundBy: 1).tap()
        fields.element(boundBy: 1).typeText("15")
        app.buttons["保存"].tap()
        XCTAssertTrue(app.staticTexts["连续 3 天 · +15 分"].waitForExistence(timeout: 5))

        // 再建一条同样周期的规则，应该被拦下来
        button(startingWith: "增加规则").tap()
        let fields2 = app.textFields
        fields2.element(boundBy: 0).tap()
        fields2.element(boundBy: 0).typeText("3")
        fields2.element(boundBy: 1).tap()
        fields2.element(boundBy: 1).typeText("9")
        app.buttons["保存"].tap()

        let toast = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "已经有连续 3 天的规则了")
        ).firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 5), "同一项目同一周期应被拦下")
    }

    // MARK: 首页常用项

    /// 用过的项会在卡片上留一个快捷入口，点一下直接记分。
    func test首页常用项一键记分() {
        goToTab("加减")
        button(startingWith: "完成作业").tap()   // +5
        sleep(1)

        goToTab("首页")
        let chip = app.buttons["recent.完成作业"].firstMatch
        XCTAssertTrue(chip.waitForExistence(timeout: 5), "用过的项应出现在卡片的常用栏")
        chip.tap()

        let toast = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "当前 10 分")
        ).firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 5), "点常用项应直接记到 10 分")
    }

    // MARK: 统计

    func test统计弹层可打开() {
        goToTab("首页")
        app.buttons["chart.bar"].tap()
        XCTAssertTrue(app.staticTexts["近 14 天积分变化趋势。"].waitForExistence(timeout: 5))
    }
}
