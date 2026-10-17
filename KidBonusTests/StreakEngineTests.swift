import XCTest
import SwiftData
@testable import KidBonus

struct StreakUpdate: Equatable { var count: Int; var bonus: Int }

final class StreakEngineTests: XCTestCase {
    @MainActor
    private func makeCtx() throws -> ModelContext {
        let schema = Schema([Kid.self, PointItem.self, Product.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: cfg)
        let ctx = container.mainContext
        SeedData.installIfEmpty(ctx: ctx)
        return ctx
    }

    @MainActor
    private func kidID(ctx: ModelContext) throws -> UUID {
        let kids = try ctx.fetch(FetchDescriptor<Kid>())
        guard let kid = kids.first else {
            throw XCTSkip()
        }
        return kid.id
    }

    @MainActor
    func testFirstBumpOfDaySetsCountToOne() throws {
        let ctx = try makeCtx()
        let id = try kidID(ctx: ctx)
        let r = StreakEngine.bump(kidID: id, ctx: ctx)
        XCTAssertEqual(r.count, 1)
        XCTAssertEqual(r.bonus, 0)
    }

    @MainActor
    func testSecondBumpSameDayDoesNotIncrement() throws {
        let ctx = try makeCtx()
        let id = try kidID(ctx: ctx)
        _ = StreakEngine.bump(kidID: id, ctx: ctx)
        let r = StreakEngine.bump(kidID: id, ctx: ctx)
        XCTAssertEqual(r.count, 1)
        XCTAssertEqual(r.bonus, 0)
    }

    @MainActor
    func testBumpAfterBreakResetsCount() throws {
        let ctx = try makeCtx()
        let id = try kidID(ctx: ctx)
        let s = Streak(kidID: id, count: 5, lastDateKey: DateKey.day(before: 3))
        ctx.insert(s)
        let r = StreakEngine.bump(kidID: id, ctx: ctx)
        XCTAssertEqual(r.count, 1, "断签后应重置为 1")
    }

    @MainActor
    func testSeventhDayTriggersWeeklyBonus() throws {
        let ctx = try makeCtx()
        let id = try kidID(ctx: ctx)
        let s = Streak(kidID: id, count: 6,
                       lastDateKey: DateKey.day(before: 1))
        ctx.insert(s)
        let r = StreakEngine.bump(kidID: id, ctx: ctx)
        XCTAssertEqual(r.count, 7)
        XCTAssertEqual(r.bonus, 20)
    }

    @MainActor
    func testThirtiethDayTriggersMonthlyBonus() throws {
        let ctx = try makeCtx()
        let id = try kidID(ctx: ctx)
        let s = Streak(kidID: id, count: 29,
                       lastDateKey: DateKey.day(before: 1))
        ctx.insert(s)
        let r = StreakEngine.bump(kidID: id, ctx: ctx)
        XCTAssertEqual(r.count, 30)
        XCTAssertEqual(r.bonus, 100)
    }
}
