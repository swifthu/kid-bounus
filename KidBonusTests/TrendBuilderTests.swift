import XCTest
import SwiftData
@testable import KidBonus

@MainActor
final class TrendBuilderTests: XCTestCase {
    private func makeFixture() throws -> (ModelContainer, Kid) {
        let schema = Schema([Kid.self, PointItem.self, Product.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: cfg)
        let ctx = container.mainContext
        let kid = Kid(name: "TestKid", age: 8, colorHex: "#FF0000")
        ctx.insert(kid)
        try ctx.save()
        return (container, kid)
    }

    func testTrendReturns14BucketsAllignedFromToday() throws {
        // container 必须保持存活：ModelContext 依赖它背后的 store，容器一旦释放访问即崩溃。
        let (container, kid) = try makeFixture()
        withExtendedLifetime(container) {
            let buckets = TrendBuilder.trend(kid, days: 14)
            XCTAssertEqual(buckets.count, 14)
            XCTAssertEqual(buckets.last?.dateKey, DateKey.today)
        }
    }

    func testTrendIncludesRedemptionAsNegative() throws {
        let (container, kid) = try makeFixture()
        let ctx = container.mainContext
        let h = HistoryRecord(kid: kid, title: "t", delta: 5, sourceKind: .preset)
        let r = Redemption(kid: kid, productName: "x", cost: 25)
        ctx.insert(h); ctx.insert(r)
        try ctx.save()
        let buckets = TrendBuilder.trend(kid, days: 14)
        let today = buckets.first { $0.dateKey == DateKey.today }
        XCTAssertEqual(today?.value, -20)
    }

    func testDistributionAggregatesByTitle() throws {
        let (container, kid) = try makeFixture()
        let ctx = container.mainContext
        let h1 = HistoryRecord(kid: kid, title: "x", delta: 5, sourceKind: .preset)
        let h2 = HistoryRecord(kid: kid, title: "x", delta: -2, sourceKind: .preset)
        ctx.insert(h1); ctx.insert(h2)
        try ctx.save()
        let dist = TrendBuilder.distribution(kid)
        let row = dist.first { $0.title == "x" }
        XCTAssertEqual(row?.add, 1)
        XCTAssertEqual(row?.deduct, 1)
    }
}
