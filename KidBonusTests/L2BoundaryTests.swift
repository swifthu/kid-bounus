import XCTest
import SwiftData
@testable import KidBonus

/// L2 边界补强：Store 层在极端输入下的行为。
@MainActor
final class L2BoundaryTests: XCTestCase {
    private var container: ModelContainer!

    override func setUp() {
        super.setUp()
        let schema = Schema([Kid.self, PointItem.self, Product.self, BonusRule.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        container = try! ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    private var ctx: ModelContext { container.mainContext }

    private func makeKid() -> Kid {
        let k = Kid(name: "小明", age: 8, colorHex: "#1B365D")
        ctx.insert(k)
        return k
    }

    // MARK: PointMath 边界

    func test空历史与空兑换为0() {
        XCTAssertEqual(PointMath.kidPoints([], []), 0)
    }

    func test仅一条加分() {
        let k = makeKid()
        ctx.insert(HistoryRecord(kid: k, title: "a", delta: 7, sourceKind: .preset))
        XCTAssertEqual(PointMath.kidPoints(k), 7)
    }

    func test多次兑换累加扣减() {
        let k = makeKid()
        ctx.insert(HistoryRecord(kid: k, title: "a", delta: 100, sourceKind: .preset))
        ctx.insert(Redemption(kid: k, productName: "p1", cost: 30))
        ctx.insert(Redemption(kid: k, productName: "p2", cost: 20))
        XCTAssertEqual(PointMath.kidPoints(k), 50)
    }

    func test负积分() {
        let k = makeKid()
        ctx.insert(HistoryRecord(kid: k, title: "a", delta: -8, sourceKind: .preset))
        XCTAssertEqual(PointMath.kidPoints(k), -8)
    }

    func test今日增量只看今天() throws {
        let k = makeKid()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        ctx.insert(HistoryRecord(kid: k, title: "昨天", delta: 50,
                                 timestamp: yesterday, sourceKind: .preset))
        ctx.insert(HistoryRecord(kid: k, title: "今天", delta: 3, sourceKind: .preset))
        XCTAssertEqual(PointMath.todayDelta(k), 3)
        XCTAssertEqual(PointMath.kidPoints(k), 53, "总积分包含所有日期")
    }

    // MARK: StreakEngine 边界
    // 连续天数按「孩子 + 加分项」分别统计，规则也挂在具体项目上。

    /// 建一个加分项，规则和连续天数都挂在它上面。
    private func makeItem(_ title: String = "完成作业") -> PointItem {
        let item = PointItem(kind: .add, title: title, delta: 5, desc: "测试项")
        ctx.insert(item)
        return item
    }

    func test第八天不再发奖() {
        let k = makeKid()
        let item = makeItem()
        ctx.insert(BonusRule(itemID: item.id, days: 7, points: 20))
        ctx.insert(Streak(kidID: k.id, itemID: item.id, count: 7, lastDateKey: DateKey.day(before: 1)))
        let r = StreakEngine.bump(kidID: k.id, itemID: item.id, ctx: ctx)
        XCTAssertEqual(r.count, 8)
        XCTAssertTrue(r.awards.isEmpty, "第 8 天不是 7 的整数倍，不该发奖")
    }

    func test第三十一天不再发奖() {
        let k = makeKid()
        let item = makeItem()
        ctx.insert(BonusRule(itemID: item.id, days: 30, points: 100))
        ctx.insert(Streak(kidID: k.id, itemID: item.id, count: 30, lastDateKey: DateKey.day(before: 1)))
        let r = StreakEngine.bump(kidID: k.id, itemID: item.id, ctx: ctx)
        XCTAssertEqual(r.count, 31)
        XCTAssertTrue(r.awards.isEmpty)
    }

    func test断签后从1重新开始() {
        let k = makeKid()
        let item = makeItem()
        ctx.insert(Streak(kidID: k.id, itemID: item.id, count: 9, lastDateKey: DateKey.day(before: 5)))
        let r = StreakEngine.bump(kidID: k.id, itemID: item.id, ctx: ctx)
        XCTAssertEqual(r.count, 1)
        XCTAssertTrue(r.awards.isEmpty)
    }

    func test断签后重新攒到第七天再次发奖() {
        let k = makeKid()
        let item = makeItem()
        ctx.insert(BonusRule(itemID: item.id, days: 7, points: 20))
        // 上次断在第 3 天，两天前开始重新累计，昨天是新的第 1 天，今天应为第 2 天
        ctx.insert(Streak(kidID: k.id, itemID: item.id, count: 1, lastDateKey: DateKey.day(before: 1)))
        let r = StreakEngine.bump(kidID: k.id, itemID: item.id, ctx: ctx)
        XCTAssertEqual(r.count, 2)
        XCTAssertTrue(r.awards.isEmpty)
    }

    func test连续三十天只发一次奖励() {
        let k = makeKid()
        let item = makeItem()
        ctx.insert(BonusRule(itemID: item.id, days: 30, points: 100))
        ctx.insert(Streak(kidID: k.id, itemID: item.id, count: 29, lastDateKey: DateKey.day(before: 1)))
        let first = StreakEngine.bump(kidID: k.id, itemID: item.id, ctx: ctx)
        XCTAssertEqual(first.count, 30)
        XCTAssertEqual(first.awards, [StreakAward(days: 30, points: 100)])
        let second = StreakEngine.bump(kidID: k.id, itemID: item.id, ctx: ctx)
        XCTAssertEqual(second.count, 30, "同一天重复 bump 不应递增")
        XCTAssertTrue(second.awards.isEmpty)
    }

    func test不同孩子的streak互不干扰() {
        let a = makeKid()
        let b = Kid(name: "小红", age: 10, colorHex: "#4A6B3A")
        ctx.insert(b)
        let item = makeItem()
        ctx.insert(BonusRule(itemID: item.id, days: 7, points: 20))
        ctx.insert(Streak(kidID: a.id, itemID: item.id, count: 6, lastDateKey: DateKey.day(before: 1)))
        ctx.insert(Streak(kidID: b.id, itemID: item.id, count: 3, lastDateKey: DateKey.day(before: 1)))
        XCTAssertEqual(StreakEngine.bump(kidID: a.id, itemID: item.id, ctx: ctx).awards,
                       [StreakAward(days: 7, points: 20)])
        XCTAssertTrue(StreakEngine.bump(kidID: b.id, itemID: item.id, ctx: ctx).awards.isEmpty)
    }

    // MARK: TrendBuilder 边界

    func test空历史趋势全为0() {
        let k = makeKid()
        let trend = TrendBuilder.trend(k, days: 14)
        XCTAssertEqual(trend.count, 14)
        XCTAssertTrue(trend.allSatisfy { $0.value == 0 })
    }

    func test全正数据() {
        let k = makeKid()
        ctx.insert(HistoryRecord(kid: k, title: "a", delta: 10, sourceKind: .preset))
        let today = TrendBuilder.trend(k, days: 14).first { $0.dateKey == DateKey.today }
        XCTAssertEqual(today?.value, 10)
    }

    func test全负数据() {
        let k = makeKid()
        ctx.insert(HistoryRecord(kid: k, title: "a", delta: -10, sourceKind: .preset))
        let today = TrendBuilder.trend(k, days: 14).first { $0.dateKey == DateKey.today }
        XCTAssertEqual(today?.value, -10)
    }

    func test兑换并入当日桶为负() {
        let k = makeKid()
        ctx.insert(Redemption(kid: k, productName: "冰淇淋", cost: 30))
        let today = TrendBuilder.trend(k, days: 14).first { $0.dateKey == DateKey.today }
        XCTAssertEqual(today?.value, -30)
    }

    func test趋势按时间从旧到新() {
        let k = makeKid()
        let trend = TrendBuilder.trend(k, days: 14)
        XCTAssertEqual(trend.first?.dateKey, DateKey.day(before: 13))
        XCTAssertEqual(trend.last?.dateKey, DateKey.today)
    }

    func test分布按标题聚合加扣() {
        let k = makeKid()
        ctx.insert(HistoryRecord(kid: k, title: "作业", delta: 5, sourceKind: .preset))
        ctx.insert(HistoryRecord(kid: k, title: "作业", delta: 5, sourceKind: .preset))
        ctx.insert(HistoryRecord(kid: k, title: "作业", delta: -5, sourceKind: .preset))
        let row = TrendBuilder.distribution(k).first { $0.title == "作业" }
        XCTAssertEqual(row?.add, 2)
        XCTAssertEqual(row?.deduct, 1)
    }

    func test空历史分布为空() {
        XCTAssertTrue(TrendBuilder.distribution(makeKid()).isEmpty)
    }

    // MARK: SeedData 完整性

    func test重置会清空全部六类实体() throws {
        SeedData.installFresh(ctx: ctx)
        let k = (try ctx.fetch(FetchDescriptor<Kid>()))[0]
        ctx.insert(HistoryRecord(kid: k, title: "x", delta: 5, sourceKind: .preset))
        ctx.insert(Redemption(kid: k, productName: "y", cost: 5))
        ctx.insert(Streak(kidID: k.id, count: 3, lastDateKey: DateKey.today))
        try? ctx.save()

        SeedData.installFresh(ctx: ctx)

        XCTAssertEqual(try ctx.fetchCount(FetchDescriptor<Kid>()), 2)
        XCTAssertEqual(try ctx.fetchCount(FetchDescriptor<HistoryRecord>()), 0)
        XCTAssertEqual(try ctx.fetchCount(FetchDescriptor<Redemption>()), 0)
        XCTAssertEqual(try ctx.fetchCount(FetchDescriptor<Streak>()), 0, "重置也应清空连续天数")

        // 重置已销毁旧的 k，必须重新取；继续访问旧实例会崩溃。
        let fresh = try XCTUnwrap(try ctx.fetch(FetchDescriptor<Kid>()).first)
        XCTAssertEqual(PointMath.kidPoints(fresh), 0, "重置后积分为 0")
        XCTAssertEqual(PointMath.todayDelta(fresh), 0)
    }

    func test种子数据内容正确() throws {
        SeedData.installFresh(ctx: ctx)
        let items = try! ctx.fetch(FetchDescriptor<PointItem>())
        let products = try! ctx.fetch(FetchDescriptor<Product>())
        XCTAssertEqual(items.filter { $0.kind == .add }.count, 7)
        XCTAssertEqual(items.filter { $0.kind == .deduct }.count, 5)
        XCTAssertTrue(items.filter { $0.kind == .add }.allSatisfy { $0.delta > 0 })
        XCTAssertTrue(items.filter { $0.kind == .deduct }.allSatisfy { $0.delta < 0 })
        XCTAssertEqual(products.count, 8)
        XCTAssertTrue(products.allSatisfy { $0.cost > 0 })
    }
}
