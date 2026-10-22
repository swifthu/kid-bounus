import XCTest
import SwiftData
@testable import KidBonus

/// 删记录后的撤销：积分要能原样回来。
@MainActor
final class RecordActionsTests: XCTestCase {
    private var container: ModelContainer!

    override func setUp() {
        super.setUp()
        let schema = Schema([Kid.self, PointItem.self, Product.self, BonusRule.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        container = try! ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    private var ctx: ModelContext { container.mainContext }

    private func makeKid() -> Kid {
        let k = Kid(name: "小明", age: 8, colorHex: "#1B365D")
        ctx.insert(k)
        return k
    }

    func test删除记录后积分回调并可撤销() throws {
        let kid = makeKid()
        let record = HistoryRecord(kid: kid, title: "完成作业", delta: 5, sourceKind: .preset)
        ctx.insert(record)
        try ctx.save()
        XCTAssertEqual(PointMath.kidPoints(kid), 5)

        let toast = ToastCenter()
        RecordActions.deleteRecord(record, ctx: ctx, toast: toast)

        XCTAssertEqual(PointMath.kidPoints(kid), 0, "删掉记录即回调积分")
        let action = try XCTUnwrap(toast.current?.action, "删除后应给出撤销入口")
        XCTAssertEqual(action.title, "撤销")

        action.handler()

        XCTAssertEqual(PointMath.kidPoints(kid), 5, "撤销后积分要回来")
        XCTAssertEqual(kid.history.count, 1)
        XCTAssertEqual(kid.history.first?.title, "完成作业")
    }

    func test撤销兑换后商品记录和分数都回来() throws {
        let kid = makeKid()
        ctx.insert(HistoryRecord(kid: kid, title: "攒分", delta: 100, sourceKind: .preset))
        let product = Product(name: "乐高积木", category: .toy, cost: 30, desc: "玩具")
        ctx.insert(product)
        try ctx.save()

        XCTAssertTrue(RecordStore.redeem(product, by: kid, ctx: ctx))
        XCTAssertEqual(PointMath.kidPoints(kid), 70)

        let toast = ToastCenter()
        let redemption = try XCTUnwrap(kid.redemptions.first)
        RecordActions.deleteRedemption(redemption, ctx: ctx, toast: toast)

        XCTAssertEqual(PointMath.kidPoints(kid), 100, "撤销兑换要把分退回")
        let action = try XCTUnwrap(toast.current?.action)
        action.handler()

        XCTAssertEqual(PointMath.kidPoints(kid), 70, "再撤销一次，兑换重新生效")
        XCTAssertEqual(kid.redemptions.count, 1)
        XCTAssertEqual(kid.redemptions.first?.cost, 30)
    }
}
