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

    /// 用户在「我的」里把规则删光后，重启不该又把默认规则塞回来。
    @MainActor
    func test规则被删光后不会被自动塞回() throws {
        UserDefaults.standard.removeObject(forKey: SeedData.rulesSeededKey)
        defer { UserDefaults.standard.removeObject(forKey: SeedData.rulesSeededKey) }

        let schema = Schema([Kid.self, PointItem.self, Product.self, BonusRule.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: cfg)
        let ctx = container.mainContext

        SeedData.installIfEmpty(ctx: ctx)
        XCTAssertEqual(try ctx.fetchCount(FetchDescriptor<BonusRule>()), 2, "首次应装上默认规则")

        // 用户把规则删光
        try ctx.delete(model: BonusRule.self)
        try ctx.save()

        // 再启动一次
        SeedData.installIfEmpty(ctx: ctx)
        XCTAssertEqual(try ctx.fetchCount(FetchDescriptor<BonusRule>()), 0,
                       "用户删光规则后不该被自动塞回")
    }
}
