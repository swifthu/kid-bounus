import XCTest
import SwiftData
@testable import KidBonus

/// 连续天数按「孩子 + 加分项」分别统计。
@MainActor
final class StreakEngineTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Kid.self, PointItem.self, Product.self, BonusRule.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: cfg)
    }

    private func seedKid(ctx: ModelContext) -> Kid {
        let k = Kid(name: "TestKid", age: 8, colorHex: "#FF0000")
        ctx.insert(k)
        return k
    }

    private func seedItem(ctx: ModelContext, _ title: String = "完成作业") -> PointItem {
        let item = PointItem(kind: .add, title: title, delta: 5, desc: "测试项")
        ctx.insert(item)
        return item
    }

    private func kidID(ctx: ModelContext) throws -> UUID {
        try ctx.fetch(FetchDescriptor<Kid>()).first!.id
    }

    func testFirstBumpOfDaySetsCountToOne() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        seedKid(ctx: ctx)
        let item = seedItem(ctx: ctx)
        let r = StreakEngine.bump(kidID: try kidID(ctx: ctx), itemID: item.id, ctx: ctx)
        XCTAssertEqual(r.count, 1)
        XCTAssertTrue(r.awards.isEmpty)
    }

    func testSecondBumpSameDayDoesNotIncrement() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        seedKid(ctx: ctx)
        let item = seedItem(ctx: ctx)
        let id = try kidID(ctx: ctx)
        _ = StreakEngine.bump(kidID: id, itemID: item.id, ctx: ctx)
        let r = StreakEngine.bump(kidID: id, itemID: item.id, ctx: ctx)
        XCTAssertEqual(r.count, 1)
        XCTAssertTrue(r.awards.isEmpty)
    }

    func testBumpAfterBreakResetsCount() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        seedKid(ctx: ctx)
        let item = seedItem(ctx: ctx)
        let s = Streak(kidID: try kidID(ctx: ctx), itemID: item.id, count: 5,
                       lastDateKey: DateKey.day(before: 3))
        ctx.insert(s)
        let r = StreakEngine.bump(kidID: try kidID(ctx: ctx), itemID: item.id, ctx: ctx)
        XCTAssertEqual(r.count, 1, "断签后应重置为 1")
    }

    func testSeventhDayTriggersWeeklyBonus() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        seedKid(ctx: ctx)
        let item = seedItem(ctx: ctx)
        ctx.insert(BonusRule(itemID: item.id, days: 7, points: 20))
        let id = try kidID(ctx: ctx)
        let s = Streak(kidID: id, itemID: item.id, count: 6, lastDateKey: DateKey.day(before: 1))
        ctx.insert(s)
        let r = StreakEngine.bump(kidID: id, itemID: item.id, ctx: ctx)
        XCTAssertEqual(r.count, 7)
        XCTAssertEqual(r.awards, [StreakAward(days: 7, points: 20)])
    }

    /// 规则是「每满 N 天」，所以第 14 天还要再发一次 7 天奖励。
    func testFourteenthDayTriggersWeeklyBonusAgain() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        seedKid(ctx: ctx)
        let item = seedItem(ctx: ctx)
        ctx.insert(BonusRule(itemID: item.id, days: 7, points: 20))
        let id = try kidID(ctx: ctx)
        let s = Streak(kidID: id, itemID: item.id, count: 13, lastDateKey: DateKey.day(before: 1))
        ctx.insert(s)
        let r = StreakEngine.bump(kidID: id, itemID: item.id, ctx: ctx)
        XCTAssertEqual(r.count, 14)
        XCTAssertEqual(r.awards, [StreakAward(days: 7, points: 20)])
    }

    /// 核心：不同项目的连续天数各算各的。
    /// 「每天读书」和「每天练琴」混在一起算没有意义。
    func test不同项目的连续天数互不影响() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        seedKid(ctx: ctx)
        let read = seedItem(ctx: ctx, "阅读 30 分")
        let piano = seedItem(ctx: ctx, "主动练琴")
        let id = try kidID(ctx: ctx)

        // 读书已经连续 6 天
        ctx.insert(Streak(kidID: id, itemID: read.id, count: 6, lastDateKey: DateKey.day(before: 1)))
        // 练琴刚第一天
        ctx.insert(Streak(kidID: id, itemID: piano.id, count: 1, lastDateKey: DateKey.day(before: 1)))

        let r1 = StreakEngine.bump(kidID: id, itemID: read.id, ctx: ctx)
        let r2 = StreakEngine.bump(kidID: id, itemID: piano.id, ctx: ctx)

        XCTAssertEqual(r1.count, 7, "读书连续到第 7 天")
        XCTAssertEqual(r2.count, 2, "练琴才第 2 天，不该被读书带着走")
    }

    /// 同一个项目，两个孩子各算各的。
    func test不同孩子的同一项目连续天数互不影响() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let a = seedKid(ctx: ctx)
        let b = Kid(name: "小红", age: 10, colorHex: "#4A6B3A")
        ctx.insert(b)
        let item = seedItem(ctx: ctx)
        ctx.insert(Streak(kidID: a.id, itemID: item.id, count: 6, lastDateKey: DateKey.day(before: 1)))
        ctx.insert(Streak(kidID: b.id, itemID: item.id, count: 2, lastDateKey: DateKey.day(before: 1)))

        XCTAssertEqual(StreakEngine.bump(kidID: a.id, itemID: item.id, ctx: ctx).count, 7)
        XCTAssertEqual(StreakEngine.bump(kidID: b.id, itemID: item.id, ctx: ctx).count, 3)
    }

    /// 规则只对它指定的那个项目生效。
    func test规则只对指定的项目生效() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        seedKid(ctx: ctx)
        let brush = seedItem(ctx: ctx, "刷牙早晚")
        let read = seedItem(ctx: ctx, "阅读 30 分")
        ctx.insert(BonusRule(itemID: brush.id, days: 7, points: 10))
        let id = try kidID(ctx: ctx)

        ctx.insert(Streak(kidID: id, itemID: read.id, count: 6, lastDateKey: DateKey.day(before: 1)))
        let r = StreakEngine.bump(kidID: id, itemID: read.id, ctx: ctx)
        XCTAssertEqual(r.count, 7)
        XCTAssertTrue(r.awards.isEmpty, "读书没有规则，不该发奖")
    }

    /// 连续天数只算还在坚持的：断了三天以上就不显示了。
    func test断了很久的连续天数不再显示() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        seedKid(ctx: ctx)
        let item = seedItem(ctx: ctx)
        let id = try kidID(ctx: ctx)
        ctx.insert(Streak(kidID: id, itemID: item.id, count: 9, lastDateKey: DateKey.day(before: 5)))

        XCTAssertEqual(StreakEngine.bestLiveStreak(kidID: id, ctx: ctx).days, 0)
    }
}
