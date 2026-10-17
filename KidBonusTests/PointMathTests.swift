import XCTest
import SwiftData
@testable import KidBonus

final class PointMathTests: XCTestCase {
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
    func testKidPointsSumOfHistoryMinusRedemptions() throws {
        let (ctx, kid) = try makeCtx()
        ctx.insert(HistoryRecord(kid: kid, title: "完成作业", delta: 5, sourceKind: .preset))
        ctx.insert(HistoryRecord(kid: kid, title: "忘带作业", delta: -5, sourceKind: .preset))
        ctx.insert(Redemption(kid: kid, productName: "贴纸", cost: 25))
        try ctx.save()
        XCTAssertEqual(PointMath.kidPoints(kid), -25)
    }

    @MainActor
    func testTodayDeltaCountsOnlyTodayRecords() throws {
        let (ctx, kid) = try makeCtx()
        ctx.insert(HistoryRecord(kid: kid, title: "t1", delta: 3, sourceKind: .preset))
        ctx.insert(HistoryRecord(kid: kid, title: "t2", delta: -2, sourceKind: .preset))
        try ctx.save()
        XCTAssertEqual(PointMath.todayDelta(kid), 1)
    }
}
