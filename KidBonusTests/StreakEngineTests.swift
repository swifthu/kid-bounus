import XCTest
import SwiftData
@testable import KidBonus

@MainActor
final class StreakEngineTests: XCTestCase {
    private func makeCtx() throws -> ModelContext {
        let schema = Schema([Kid.self, PointItem.self, Product.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: cfg)
        return container.mainContext
    }

    private func seedKid(ctx: ModelContext) {
        ctx.insert(Kid(name: "TestKid", age: 8, colorHex: "#FF0000"))
    }

    func testFirstBumpOfDaySetsCountToOne() throws {
        let ctx = try makeCtx()
        seedKid(ctx: ctx)
        let kids = try ctx.fetch(FetchDescriptor<Kid>())
        let id = kids.first!.id
        let r = StreakEngine.bump(kidID: id, ctx: ctx)
        XCTAssertEqual(r.count, 1)
        XCTAssertEqual(r.bonus, 0)
    }

    func testSecondBumpSameDayDoesNotIncrement() throws {
        let ctx = try makeCtx()
        seedKid(ctx: ctx)
        let kids = try ctx.fetch(FetchDescriptor<Kid>())
        let id = kids.first!.id
        _ = StreakEngine.bump(kidID: id, ctx: ctx)
        let r = StreakEngine.bump(kidID: id, ctx: ctx)
        XCTAssertEqual(r.count, 1)
        XCTAssertEqual(r.bonus, 0)
    }

    func testBumpAfterBreakResetsCount() throws {
        let ctx = try makeCtx()
        seedKid(ctx: ctx)
        let kids = try ctx.fetch(FetchDescriptor<Kid>())
        let id = kids.first!.id
        let s = Streak(kidID: id, count: 5, lastDateKey: DateKey.day(before: 3))
        ctx.insert(s)
        let r = StreakEngine.bump(kidID: id, ctx: ctx)
        XCTAssertEqual(r.count, 1, "断签后应重置为 1")
    }

    func testSeventhDayTriggersWeeklyBonus() throws {
        let ctx = try makeCtx()
        seedKid(ctx: ctx)
        let kids = try ctx.fetch(FetchDescriptor<Kid>())
        let id = kids.first!.id
        let s = Streak(kidID: id, count: 6,
                       lastDateKey: DateKey.day(before: 1))
        ctx.insert(s)
        let r = StreakEngine.bump(kidID: id, ctx: ctx)
        XCTAssertEqual(r.count, 7)
        XCTAssertEqual(r.bonus, 20)
    }

    func testThirtiethDayTriggersMonthlyBonus() throws {
        let ctx = try makeCtx()
        seedKid(ctx: ctx)
        let kids = try ctx.fetch(FetchDescriptor<Kid>())
        let id = kids.first!.id
        let s = Streak(kidID: id, count: 29,
                       lastDateKey: DateKey.day(before: 1))
        ctx.insert(s)
        let r = StreakEngine.bump(kidID: id, ctx: ctx)
        XCTAssertEqual(r.count, 30)
        XCTAssertEqual(r.bonus, 100)
    }
}
