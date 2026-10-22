import XCTest
import SwiftData
@testable import KidBonus

/// 商城筛选依赖 Product / Kid 实体，因此走内存 ModelContainer。
@MainActor
final class ShopFilterTests: XCTestCase {
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

    private func makeProduct(_ name: String, _ cat: ProductCategory, _ cost: Int) -> Product {
        Product(name: name, category: cat, cost: cost, desc: "")
    }

    func testnil分类返回全部() {
        let ps = [makeProduct("A", .toy, 10), makeProduct("B", .book, 20)]
        XCTAssertEqual(ShopFilter.filter(ps, category: nil).count, 2)
    }

    func test按分类过滤() {
        let ps = [makeProduct("A", .toy, 10), makeProduct("B", .book, 20), makeProduct("C", .toy, 30)]
        let toys = ShopFilter.filter(ps, category: .toy)
        XCTAssertEqual(toys.map(\.name), ["C", "A"])
    }

    func test按价格降序() {
        let ps = [makeProduct("便宜", .toy, 10), makeProduct("贵", .toy, 200), makeProduct("中", .toy, 80)]
        XCTAssertEqual(ShopFilter.filter(ps, category: nil).map(\.name), ["贵", "中", "便宜"])
    }

    func test无匹配分类返回空() {
        let ps = [makeProduct("A", .toy, 10)]
        XCTAssertTrue(ShopFilter.filter(ps, category: .food).isEmpty)
    }

    func test空列表() {
        XCTAssertTrue(ShopFilter.filter([], category: nil).isEmpty)
    }

    func test无孩子时bestPoints为0() {
        XCTAssertEqual(ShopFilter.bestPoints([]), 0)
    }

    func testbestPoints取积分最高的孩子() throws {
        let ctx = container.mainContext
        let k1 = Kid(name: "小明", age: 8, colorHex: "#111111")
        let k2 = Kid(name: "小红", age: 10, colorHex: "#222222")
        ctx.insert(k1); ctx.insert(k2)
        ctx.insert(HistoryRecord(kid: k1, title: "a", delta: 10, sourceKind: .preset))
        ctx.insert(HistoryRecord(kid: k2, title: "b", delta: 30, sourceKind: .preset))
        try ctx.save()
        XCTAssertEqual(ShopFilter.bestPoints([k1, k2]), 30)
    }

    func test可负担判断与差额() {
        let p = makeProduct("贴纸", .toy, 25)
        XCTAssertTrue(ShopFilter.isAffordable(p, points: 25))
        XCTAssertFalse(ShopFilter.isAffordable(p, points: 24))
        XCTAssertEqual(ShopFilter.shortfall(p, points: 24), 1)
        XCTAssertEqual(ShopFilter.shortfall(p, points: 100), 0)
    }
}
