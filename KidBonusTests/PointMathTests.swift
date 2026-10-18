import XCTest
import SwiftData
@testable import KidBonus

@MainActor
final class PointMathTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Kid.self, PointItem.self, Product.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: cfg)
    }

    func testKidPointsSumOfHistoryMinusRedemptions() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let kid = Kid(name: "TestKid", age: 8, colorHex: "#FF0000")
        ctx.insert(kid)
        let h1 = HistoryRecord(kid: kid, title: "完成作业", delta: 5, sourceKind: .preset)
        let h2 = HistoryRecord(kid: kid, title: "忘带作业", delta: -5, sourceKind: .preset)
        let r = Redemption(kid: kid, productName: "贴纸", cost: 25)
        ctx.insert(h1); ctx.insert(h2); ctx.insert(r)
        try ctx.save()
        XCTAssertEqual(PointMath.kidPoints([h1, h2], [r]), -25)
    }

    func testTodayDeltaCountsOnlyTodayRecords() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let kid = Kid(name: "TestKid", age: 8, colorHex: "#FF0000")
        ctx.insert(kid)
        let h1 = HistoryRecord(kid: kid, title: "t1", delta: 3, sourceKind: .preset)
        let h2 = HistoryRecord(kid: kid, title: "t2", delta: -2, sourceKind: .preset)
        ctx.insert(h1); ctx.insert(h2)
        try ctx.save()
        XCTAssertEqual(PointMath.todayDelta([h1, h2]), 1)
    }
}
