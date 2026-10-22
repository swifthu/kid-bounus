import XCTest
import SwiftData
@testable import KidBonus

final class SeedDataTests: XCTestCase {
    @MainActor
    func testInstallIfEmptySeedsKidsAndItems() throws {
        let schema = Schema([Kid.self, PointItem.self, Product.self, BonusRule.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: cfg)
        let ctx = container.mainContext
        SeedData.installIfEmpty(ctx: ctx)
        let kids = try ctx.fetch(FetchDescriptor<Kid>())
        let items = try ctx.fetch(FetchDescriptor<PointItem>())
        let products = try ctx.fetch(FetchDescriptor<Product>())
        XCTAssertEqual(kids.count, 2)
        XCTAssertGreaterThan(items.count, 5)
        XCTAssertGreaterThan(products.count, 5)
    }

    @MainActor
    func testInstallIfEmptyIsIdempotent() throws {
        let schema = Schema([Kid.self, PointItem.self, Product.self, BonusRule.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: cfg)
        let ctx = container.mainContext
        SeedData.installIfEmpty(ctx: ctx)
        SeedData.installIfEmpty(ctx: ctx) // second call should not add more
        let kids = try ctx.fetch(FetchDescriptor<Kid>())
        XCTAssertEqual(kids.count, 2)
    }

    @MainActor
    func testInstallFreshWipesAndReseeds() throws {
        let schema = Schema([Kid.self, PointItem.self, Product.self, BonusRule.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: cfg)
        let ctx = container.mainContext
        SeedData.installIfEmpty(ctx: ctx)
        let k1 = try ctx.fetch(FetchDescriptor<Kid>()).first!
        ctx.insert(HistoryRecord(kid: k1, title: "test", delta: 5, sourceKind: .preset))
        SeedData.installFresh(ctx: ctx)
        let kids = try ctx.fetch(FetchDescriptor<Kid>())
        let hist = try ctx.fetch(FetchDescriptor<HistoryRecord>())
        XCTAssertEqual(kids.count, 2)
        XCTAssertEqual(hist.count, 0)
    }
}
