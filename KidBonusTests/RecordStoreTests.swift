import XCTest
import SwiftData
@testable import KidBonus

@MainActor
final class RecordStoreTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Kid.self, PointItem.self, Product.self, BonusRule.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: cfg)
    }

    func testRecordItemAddsHistoryAndRecomputesPoints() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
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
        let container = try makeContainer()
        let ctx = container.mainContext
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

    // MARK: 删除记录并回调积分

    func test删除加分记录会回调分数() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let kid = Kid(name: "小明", age: 8, colorHex: "#1B365D")
        ctx.insert(kid)
        let item = PointItem(kind: .add, title: "完成作业", delta: 5, desc: "d")
        ctx.insert(item)

        _ = RecordStore.recordItem(item, on: kid, ctx: ctx)
        let record = try XCTUnwrap(kid.history.first)

        let points = RecordStore.deleteRecord(record, ctx: ctx)

        XCTAssertEqual(points, 0, "删掉 +5 后积分应回到 0")
        XCTAssertTrue(kid.history.isEmpty)
    }

    func test删除扣分记录会回调分数() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let kid = Kid(name: "小明", age: 8, colorHex: "#1B365D")
        ctx.insert(kid)
        let item = PointItem(kind: .deduct, title: "忘带作业", delta: -5, desc: "d")
        ctx.insert(item)

        _ = RecordStore.recordItem(item, on: kid, ctx: ctx)
        let record = try XCTUnwrap(kid.history.first)

        let points = RecordStore.deleteRecord(record, ctx: ctx)

        XCTAssertEqual(points, 0, "删掉 -5 后应把扣掉的分还回去")
    }

    func test删除一条不影响同孩子其他记录() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let kid = Kid(name: "小明", age: 8, colorHex: "#1B365D")
        ctx.insert(kid)
        let a = PointItem(kind: .add, title: "A", delta: 5, desc: "d")
        let b = PointItem(kind: .add, title: "B", delta: 8, desc: "d")
        ctx.insert(a); ctx.insert(b)

        _ = RecordStore.recordItem(a, on: kid, ctx: ctx)
        _ = RecordStore.recordItem(b, on: kid, ctx: ctx)
        let record = try XCTUnwrap(kid.history.first { $0.title == "A" })

        let points = RecordStore.deleteRecord(record, ctx: ctx)

        XCTAssertEqual(points, 8)
        XCTAssertEqual(kid.history.count, 1)
    }

    /// 兑换过的分不因删除历史而变化，两者是各自独立的汇总项。
    func test删除记录不影响兑换消耗() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let kid = Kid(name: "小明", age: 8, colorHex: "#1B365D")
        ctx.insert(kid)
        let item = PointItem(kind: .add, title: "A", delta: 100, desc: "d")
        ctx.insert(item)
        let product = Product(name: "Toy", category: .toy, cost: 30, desc: "d")
        ctx.insert(product)

        _ = RecordStore.recordItem(item, on: kid, ctx: ctx)
        _ = RecordStore.redeem(product, by: kid, ctx: ctx)
        let record = try XCTUnwrap(kid.history.first)

        let points = RecordStore.deleteRecord(record, ctx: ctx)

        XCTAssertEqual(points, -30, "删掉历史后仍应扣着兑换的 30 分")
    }

    // MARK: 直接设定积分

    func test设定积分写入差额记录() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let kid = Kid(name: "小明", age: 8, colorHex: "#1B365D")
        ctx.insert(kid)
        let item = PointItem(kind: .add, title: "A", delta: 20, desc: "d")
        ctx.insert(item)
        _ = RecordStore.recordItem(item, on: kid, ctx: ctx)

        let points = RecordStore.setPoints(100, for: kid, ctx: ctx)

        XCTAssertEqual(points, 100)
        XCTAssertEqual(kid.history.count, 2, "应多出一条差额记录")
        // 关系数组无序，按来源找那条差额记录
        let adjust = try XCTUnwrap(kid.history.first { $0.sourceKind == .adjust })
        XCTAssertEqual(adjust.delta, 80)
        XCTAssertEqual(adjust.title, "设定积分为 100")
    }

    func test设定为当前积分不产生记录() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let kid = Kid(name: "小明", age: 8, colorHex: "#1B365D")
        ctx.insert(kid)
        let item = PointItem(kind: .add, title: "A", delta: 20, desc: "d")
        ctx.insert(item)
        _ = RecordStore.recordItem(item, on: kid, ctx: ctx)

        let points = RecordStore.setPoints(20, for: kid, ctx: ctx)

        XCTAssertEqual(points, 20)
        XCTAssertEqual(kid.history.count, 1, "没有差额就不该写记录")
    }

    /// 设定值可以和当前积分不同向，比如把扣掉的分补回来。
    func test设定积分可以调低() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let kid = Kid(name: "小明", age: 8, colorHex: "#1B365D")
        ctx.insert(kid)
        let item = PointItem(kind: .add, title: "A", delta: 50, desc: "d")
        ctx.insert(item)
        _ = RecordStore.recordItem(item, on: kid, ctx: ctx)

        let points = RecordStore.setPoints(10, for: kid, ctx: ctx)

        XCTAssertEqual(points, 10)
        let adjust = try XCTUnwrap(kid.history.first { $0.sourceKind == .adjust })
        XCTAssertEqual(adjust.delta, -40)
    }
}
