import XCTest
import SwiftData
@testable import KidBonus

final class TrendBuilderTests: XCTestCase {
    @MainActor
    private func makeCtx() throws -> (ModelContext, Kid) {
        let schema = Schema([Kid.self, PointItem.self, Product.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: cfg)
        let ctx = container.mainContext
        SeedData.installIfEmpty(ctx: ctx)
        let kid = try ctx.fetch(FetchDescriptor<Kid>()).first!
        return (ctx, kid)
    }

    @MainActor
    func testTrendReturns14BucketsAllignedFromToday() throws {
        let (_, kid) = try makeCtx()
        let buckets = TrendBuilder.trend(kid, days: 14)
        XCTAssertEqual(buckets.count, 14)
        XCTAssertEqual(buckets.last?.dateKey, DateKey.today)
    }

    @MainActor
    func testTrendIncludesRedemptionAsNegative() throws {
        let (ctx, kid) = try makeCtx()
        ctx.insert(HistoryRecord(kid: kid, title: "t", delta: 5,
                                 sourceKind: .preset))
        ctx.insert(Redemption(kid: kid, productName: "x", cost: 25))
        try ctx.save()
        let buckets = TrendBuilder.trend(kid, days: 14)
        let today = buckets.first { $0.dateKey == DateKey.today }
        XCTAssertEqual(today?.value, -20)
    }

    @MainActor
    func testDistributionAggregatesByTitle() throws {
        let (ctx, kid) = try makeCtx()
        ctx.insert(HistoryRecord(kid: kid, title: "x", delta: 5, sourceKind: .preset))
        ctx.insert(HistoryRecord(kid: kid, title: "x", delta: -2, sourceKind: .preset))
        try ctx.save()
        let dist = TrendBuilder.distribution(kid)
        let row = dist.first { $0.title == "x" }
        XCTAssertEqual(row?.add, 1)
        XCTAssertEqual(row?.deduct, 1)
    }
}
