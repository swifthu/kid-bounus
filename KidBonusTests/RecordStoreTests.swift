import XCTest
import SwiftData
@testable import KidBonus

@MainActor
final class RecordStoreTests: XCTestCase {
    private func makeCtx() throws -> ModelContext {
        let schema = Schema([Kid.self, PointItem.self, Product.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: cfg)
        return container.mainContext
    }

    func testRecordItemAddsHistoryAndRecomputesPoints() throws {
        let ctx = try makeCtx()
        let kid = Kid(name: "TestKid", age: 8, colorHex: "#FF0000")
        ctx.insert(kid)

        let item = PointItem(kind: .add, title: "Test Item", delta: 5, desc: "desc")
        ctx.insert(item)

        let outcome = RecordStore.recordItem(item, on: kid, ctx: ctx)

        XCTAssertEqual(outcome.points, 5)
        XCTAssertEqual(outcome.streakCount, 1)
        XCTAssertEqual(outcome.streakBonus, 0)
    }

    func testRedeemRefusesWhenInsufficient() throws {
        let ctx = try makeCtx()
        let kid = Kid(name: "TestKid", age: 8, colorHex: "#FF0000")
        ctx.insert(kid)

        let product = Product(
            name: "Toy",
            category: .toy,
            cost: 50,
            desc: "A toy"
        )
        ctx.insert(product)

        let success = RecordStore.redeem(product, by: kid, ctx: ctx)

        XCTAssertFalse(success)
    }
}
