import XCTest
import SwiftData
@testable import KidBonus

/// 加分 / 扣分 / 消费 三条主流程的行为测试。
/// 覆盖积分算术、连续天数推进规则、兑换门槛与边界。
@MainActor
final class PointFlowTests: XCTestCase {

    /// ModelContext 依赖容器背后的 store，容器一旦释放后续访问即崩溃。
    /// XCTest 每个用例都是新实例，所以把容器挂在属性上即可保证存活。
    private var container: ModelContainer!

    override func setUp() {
        super.setUp()
        container = nil
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    private func makeEnv() throws -> (ModelContext, Kid) {
        let schema = Schema([Kid.self, PointItem.self, Product.self, BonusRule.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let ctx = container.mainContext
        let kid = Kid(name: "小明", age: 8, colorHex: "#1B365D")
        ctx.insert(kid)
        try ctx.save()
        return (ctx, kid)
    }

    private func addItem(_ title: String, _ delta: Int) -> PointItem {
        PointItem(kind: delta > 0 ? .add : .deduct,
                  title: title, delta: delta, desc: "测试项")
    }

    private func product(_ name: String, _ cost: Int) -> Product {
        Product(name: name, category: .toy, cost: cost, desc: "测试商品")
    }

    // MARK: - 加分

    func test加分写入历史并增加积分() throws {
        let (ctx, kid) = try makeEnv()
        let item = addItem("完成作业", 5)

        let outcome = RecordStore.recordItem(item, on: kid, ctx: ctx)

        XCTAssertEqual(outcome.points, 5)
        XCTAssertEqual(kid.history.count, 1)
        XCTAssertEqual(kid.history.first?.title, "完成作业")
        XCTAssertEqual(kid.history.first?.delta, 5)
        XCTAssertEqual(kid.history.first?.sourceKind, .preset)
        XCTAssertEqual(PointMath.todayDelta(kid), 5)
    }

    func test多次加分积分累加() throws {
        let (ctx, kid) = try makeEnv()

        _ = RecordStore.recordItem(addItem("完成作业", 5), on: kid, ctx: ctx)
        _ = RecordStore.recordItem(addItem("主动练琴", 8), on: kid, ctx: ctx)
        let last = RecordStore.recordItem(addItem("帮忙家务", 3), on: kid, ctx: ctx)

        XCTAssertEqual(last.points, 16)
        XCTAssertEqual(kid.history.count, 3)
    }

    func test加分建立连续天数() throws {
        let (ctx, kid) = try makeEnv()
        let item = addItem("完成作业", 5)

        let outcome = RecordStore.recordItem(item, on: kid, ctx: ctx)

        XCTAssertEqual(outcome.streakCount, 1)
        XCTAssertEqual(outcome.streakBonus, 0)
        XCTAssertEqual(StreakEngine.currentStreak(kidID: kid.id, itemID: item.id, ctx: ctx)?.count, 1)
    }

    func test同日多次加分连续天数只推进一次() throws {
        let (ctx, kid) = try makeEnv()
        let item = addItem("完成作业", 5)

        _ = RecordStore.recordItem(item, on: kid, ctx: ctx)
        let second = RecordStore.recordItem(item, on: kid, ctx: ctx)

        XCTAssertEqual(second.streakCount, 1, "同一天重复加分不应把连续天数推到 2")
        XCTAssertEqual(second.points, 10)
    }

    /// 连续天数按项目分别算：做了别的项目，不会把这一项的连续天数带上去。
    func test不同项目的连续天数各算各的() throws {
        let (ctx, kid) = try makeEnv()
        let homework = addItem("完成作业", 5)
        let reading = addItem("阅读 30 分", 5)

        _ = RecordStore.recordItem(homework, on: kid, ctx: ctx)
        let second = RecordStore.recordItem(reading, on: kid, ctx: ctx)

        XCTAssertEqual(second.streakCount, 1, "阅读是另一个项目，从第 1 天开始")
        XCTAssertEqual(StreakEngine.currentStreak(kidID: kid.id, itemID: homework.id, ctx: ctx)?.count, 1)
    }

    // MARK: - 扣分

    func test扣分写入历史并减少积分() throws {
        let (ctx, kid) = try makeEnv()
        _ = RecordStore.recordItem(addItem("完成作业", 5), on: kid, ctx: ctx)

        let outcome = RecordStore.recordItem(addItem("忘带作业", -5), on: kid, ctx: ctx)

        XCTAssertEqual(outcome.points, 0)
        XCTAssertEqual(kid.history.count, 2)
        let deduct = try XCTUnwrap(kid.history.first { $0.title == "忘带作业" })
        XCTAssertEqual(deduct.delta, -5)
    }

    func test扣分不影响连续天数() throws {
        let (ctx, kid) = try makeEnv()
        let good = addItem("完成作业", 5)
        _ = RecordStore.recordItem(good, on: kid, ctx: ctx)

        let bad = addItem("挑食", -2)
        let outcome = RecordStore.recordItem(bad, on: kid, ctx: ctx)

        XCTAssertEqual(outcome.streakCount, 0, "扣分不应推进连续天数")
        XCTAssertEqual(StreakEngine.currentStreak(kidID: kid.id, itemID: good.id, ctx: ctx)?.count, 1,
                       "连续天数应停留在加分那天的 1")
    }

    func test只扣不加不会建立连续天数() throws {
        let (ctx, kid) = try makeEnv()
        let bad = addItem("赖床迟到", -3)

        let outcome = RecordStore.recordItem(bad, on: kid, ctx: ctx)

        XCTAssertEqual(outcome.points, -3)
        XCTAssertNil(StreakEngine.currentStreak(kidID: kid.id, itemID: bad.id, ctx: ctx),
                     "扣分不该产生 streak 记录")
    }

    func test扣分可以让积分变成负数() throws {
        let (ctx, kid) = try makeEnv()

        _ = RecordStore.recordItem(addItem("完成作业", 5), on: kid, ctx: ctx)
        let outcome = RecordStore.recordItem(addItem("顶嘴发脾气", -5), on: kid, ctx: ctx)

        XCTAssertEqual(outcome.points, 0)
        let third = RecordStore.recordItem(addItem("看电视超时", -2), on: kid, ctx: ctx)
        XCTAssertEqual(third.points, -2, "扣分不受余额限制，积分允许为负")
    }

    // MARK: - 消费

    func test积分足够时兑换成功并扣减积分() throws {
        let (ctx, kid) = try makeEnv()
        _ = RecordStore.recordItem(addItem("完成作业", 30), on: kid, ctx: ctx)
        let sticker = product("贴纸一包", 25)

        let ok = RecordStore.redeem(sticker, by: kid, ctx: ctx)

        XCTAssertTrue(ok)
        XCTAssertEqual(PointMath.kidPoints(kid), 5)
        XCTAssertEqual(kid.redemptions.count, 1)
        XCTAssertEqual(kid.redemptions.first?.productName, "贴纸一包")
        XCTAssertEqual(kid.redemptions.first?.cost, 25)
    }

    func test积分不足时兑换被拒绝且不留记录() throws {
        let (ctx, kid) = try makeEnv()
        _ = RecordStore.recordItem(addItem("完成作业", 10), on: kid, ctx: ctx)

        let ok = RecordStore.redeem(product("乐高积木", 200), by: kid, ctx: ctx)

        XCTAssertFalse(ok)
        XCTAssertEqual(kid.redemptions.count, 0, "失败的兑换不应留下任何记录")
        XCTAssertEqual(PointMath.kidPoints(kid), 10, "失败的兑换不应改动积分")
    }

    func test积分刚好等于价格时可以兑换() throws {
        let (ctx, kid) = try makeEnv()
        _ = RecordStore.recordItem(addItem("完成作业", 25), on: kid, ctx: ctx)

        let ok = RecordStore.redeem(product("贴纸一包", 25), by: kid, ctx: ctx)

        XCTAssertTrue(ok, "积分等于价格时应允许兑换")
        XCTAssertEqual(PointMath.kidPoints(kid), 0)
    }

    func test积分差一分也不能兑换() throws {
        let (ctx, kid) = try makeEnv()
        _ = RecordStore.recordItem(addItem("完成作业", 24), on: kid, ctx: ctx)

        let ok = RecordStore.redeem(product("贴纸一包", 25), by: kid, ctx: ctx)

        XCTAssertFalse(ok)
        XCTAssertEqual(PointMath.kidPoints(kid), 24)
    }

    func test多次兑换累积扣减() throws {
        let (ctx, kid) = try makeEnv()
        _ = RecordStore.recordItem(addItem("主动练琴", 100), on: kid, ctx: ctx)

        XCTAssertTrue(RecordStore.redeem(product("贴纸一包", 25), by: kid, ctx: ctx))
        XCTAssertTrue(RecordStore.redeem(product("冰淇淋", 30), by: kid, ctx: ctx))

        XCTAssertEqual(PointMath.kidPoints(kid), 45)
        XCTAssertEqual(kid.redemptions.count, 2)
        XCTAssertFalse(RecordStore.redeem(product("乐高积木", 200), by: kid, ctx: ctx))
        XCTAssertEqual(PointMath.kidPoints(kid), 45)
    }

    func test负积分不能兑换() throws {
        let (ctx, kid) = try makeEnv()
        _ = RecordStore.recordItem(addItem("挑食", -10), on: kid, ctx: ctx)

        let ok = RecordStore.redeem(product("贴纸一包", 25), by: kid, ctx: ctx)

        XCTAssertFalse(ok)
        XCTAssertEqual(kid.redemptions.count, 0)
    }

    // MARK: - 组合场景

    func test加减混排后积分正确() throws {
        let (ctx, kid) = try makeEnv()

        _ = RecordStore.recordItem(addItem("完成作业", 5), on: kid, ctx: ctx)    // 5
        _ = RecordStore.recordItem(addItem("主动练琴", 8), on: kid, ctx: ctx)   // 13
        _ = RecordStore.recordItem(addItem("赖床迟到", -3), on: kid, ctx: ctx)  // 10
        let outcome = RecordStore.recordItem(addItem("运动 30 分", 6), on: kid, ctx: ctx) // 16

        XCTAssertEqual(outcome.points, 16)
        XCTAssertEqual(kid.history.count, 4)
        XCTAssertEqual(PointMath.todayDelta(kid), 16)
    }

    func test消费不影响今日加分明细() throws {
        let (ctx, kid) = try makeEnv()
        _ = RecordStore.recordItem(addItem("主动练琴", 30), on: kid, ctx: ctx)

        _ = RecordStore.redeem(product("冰淇淋", 30), by: kid, ctx: ctx)

        XCTAssertEqual(PointMath.kidPoints(kid), 0, "兑换应扣减总积分")
        XCTAssertEqual(PointMath.todayDelta(kid), 30, "今日明细只统计加减分，不含兑换")
    }

    /// 自由记录没有对应的项目，不该推进任何项目的连续天数。
    func test自定义加分不推进连续天数() throws {
        let (ctx, kid) = try makeEnv()

        let outcome = RecordStore.recordFreeform(title: "主动帮忙", delta: 4, on: kid, ctx: ctx)

        XCTAssertEqual(outcome.points, 4)
        XCTAssertEqual(outcome.streakCount, 0, "自由记录没有对应项目，不推进连续天数")
        XCTAssertEqual(kid.history.first?.sourceKind, .freeform)
    }

    func test连续第七天触发奖励并计入积分() throws {
        let (ctx, kid) = try makeEnv()
        let item = addItem("完成作业", 5)
        ctx.insert(item)
        // 规则挂在这一项上：连续 7 天做「完成作业」就奖励 20 分
        ctx.insert(BonusRule(itemID: item.id, days: 7, points: 20))
        let seeded = Streak(kidID: kid.id, itemID: item.id, count: 6,
                            lastDateKey: DateKey.day(before: 1))
        ctx.insert(seeded)
        try ctx.save()

        let outcome = RecordStore.recordItem(item, on: kid, ctx: ctx)

        XCTAssertEqual(outcome.streakCount, 7)
        XCTAssertEqual(outcome.streakBonus, 20)
        XCTAssertEqual(outcome.points, 25, "5 分加分 + 20 分连续奖励")
        XCTAssertEqual(kid.history.count, 2)
        // 关系数组不保证插入顺序，按 sourceKind 定位而非依赖下标
        let bonus = try XCTUnwrap(kid.history.first { $0.sourceKind == .streakBonus })
        XCTAssertEqual(bonus.delta, 20)
        let preset = try XCTUnwrap(kid.history.first { $0.sourceKind == .preset })
        XCTAssertEqual(preset.delta, 5)
    }

    /// 用真实种子数据跑一遍「攒分 → 兑换」的完整路径。
    func test真实种子数据下攒分可兑换便宜商品() throws {
        let schema = Schema([Kid.self, PointItem.self, Product.self, BonusRule.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let ctx = container.mainContext
        SeedData.installIfEmpty(ctx: ctx)

        let kid = try XCTUnwrap(try ctx.fetch(FetchDescriptor<Kid>()).first)
        let homework = try XCTUnwrap(
            try ctx.fetch(FetchDescriptor<PointItem>())
                .first { $0.title == "完成作业" }
        )
        let sticker = try XCTUnwrap(
            try ctx.fetch(FetchDescriptor<Product>())
                .first { $0.name == "贴纸一包" }
        )
        XCTAssertEqual(sticker.cost, 25)

        // 攒够 25 分：加分 5 次
        for _ in 0..<5 {
            _ = RecordStore.recordItem(homework, on: kid, ctx: ctx)
        }
        XCTAssertEqual(PointMath.kidPoints(kid), 25)

        XCTAssertTrue(RecordStore.redeem(sticker, by: kid, ctx: ctx))
        XCTAssertEqual(PointMath.kidPoints(kid), 0)
        XCTAssertEqual(kid.redemptions.first?.productName, "贴纸一包")

        // 最贵的商品此时应买不起
        let lego = try XCTUnwrap(
            try ctx.fetch(FetchDescriptor<Product>()).first { $0.name == "乐高积木" }
        )
        XCTAssertFalse(RecordStore.redeem(lego, by: kid, ctx: ctx))
    }

    /// 两个孩子各自独立记账，互不干扰。
    func test多个孩子积分互相独立() throws {
        let (ctx, kid1) = try makeEnv()
        let kid2 = Kid(name: "小红", age: 10, colorHex: "#4A6B3A")
        ctx.insert(kid2)
        try ctx.save()

        _ = RecordStore.recordItem(addItem("完成作业", 10), on: kid1, ctx: ctx)
        _ = RecordStore.recordItem(addItem("挑食", -4), on: kid2, ctx: ctx)
        XCTAssertFalse(RecordStore.redeem(product("贴纸一包", 25), by: kid1, ctx: ctx),
                       "10 分不够兑换 25 分的商品")

        XCTAssertEqual(PointMath.kidPoints(kid1), 10)
        XCTAssertEqual(PointMath.kidPoints(kid2), -4)
        XCTAssertEqual(kid1.redemptions.count, 0)
        XCTAssertEqual(kid2.redemptions.count, 0)
    }
}
