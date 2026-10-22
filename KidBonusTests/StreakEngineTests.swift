import XCTest
import SwiftData
@testable import KidBonus

@MainActor
final class StreakEngineTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Kid.self, PointItem.self, Product.self, BonusRule.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: cfg)
    }

    private func seedKid(ctx: ModelContext) {
        ctx.insert(Kid(name: "TestKid", age: 8, colorHex: "#FF0000"))
    }

    /// 奖励由规则决定，测试里要先写好规则。
    private func seedRules(ctx: ModelContext) {
        SeedData.defaultRules().forEach(ctx.insert)
    }

    private func kidID(ctx: ModelContext) throws -> UUID {
        try ctx.fetch(FetchDescriptor<Kid>()).first!.id
    }

    func testFirstBumpOfDaySetsCountToOne() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        seedKid(ctx: ctx)
        seedRules(ctx: ctx)
        let r = StreakEngine.bump(kidID: try kidID(ctx: ctx), ctx: ctx)
        XCTAssertEqual(r.count, 1)
        XCTAssertTrue(r.awards.isEmpty)
    }

    func testSecondBumpSameDayDoesNotIncrement() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        seedKid(ctx: ctx)
        seedRules(ctx: ctx)
        let id = try kidID(ctx: ctx)
        _ = StreakEngine.bump(kidID: id, ctx: ctx)
        let r = StreakEngine.bump(kidID: id, ctx: ctx)
        XCTAssertEqual(r.count, 1)
        XCTAssertTrue(r.awards.isEmpty)
    }

    func testBumpAfterBreakResetsCount() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        seedKid(ctx: ctx)
        seedRules(ctx: ctx)
        let s = Streak(kidID: try kidID(ctx: ctx), count: 5, lastDateKey: DateKey.day(before: 3))
        ctx.insert(s)
        let r = StreakEngine.bump(kidID: try kidID(ctx: ctx), ctx: ctx)
        XCTAssertEqual(r.count, 1, "断签后应重置为 1")
    }

    func testSeventhDayTriggersWeeklyBonus() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        seedKid(ctx: ctx)
        seedRules(ctx: ctx)
        let id = try kidID(ctx: ctx)
        let s = Streak(kidID: id, count: 6, lastDateKey: DateKey.day(before: 1))
        ctx.insert(s)
        let r = StreakEngine.bump(kidID: id, ctx: ctx)
        XCTAssertEqual(r.count, 7)
        XCTAssertEqual(r.awards, [StreakAward(days: 7, points: 20)])
    }

    func testThirtiethDayTriggersMonthlyBonus() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        seedKid(ctx: ctx)
        seedRules(ctx: ctx)
        let id = try kidID(ctx: ctx)
        let s = Streak(kidID: id, count: 29, lastDateKey: DateKey.day(before: 1))
        ctx.insert(s)
        let r = StreakEngine.bump(kidID: id, ctx: ctx)
        XCTAssertEqual(r.count, 30)
        XCTAssertEqual(r.awards, [StreakAward(days: 30, points: 100)])
    }

    /// 规则是「每满 N 天」，所以第 14 天还要再发一次 7 天奖励。
    func testFourteenthDayTriggersWeeklyBonusAgain() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        seedKid(ctx: ctx)
        seedRules(ctx: ctx)
        let id = try kidID(ctx: ctx)
        let s = Streak(kidID: id, count: 13, lastDateKey: DateKey.day(before: 1))
        ctx.insert(s)
        let r = StreakEngine.bump(kidID: id, ctx: ctx)
        XCTAssertEqual(r.count, 14)
        XCTAssertEqual(r.awards, [StreakAward(days: 7, points: 20)])
    }
}
