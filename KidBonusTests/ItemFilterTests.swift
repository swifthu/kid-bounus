import XCTest
@testable import KidBonus

/// L1 纯逻辑：加减分项按归属孩子过滤。
final class ItemFilterTests: XCTestCase {
    private let a = UUID()
    private let b = UUID()

    private func item(_ title: String, kidID: UUID?) -> PointItem {
        PointItem(kind: .add, title: title, delta: 5, desc: "d", kidID: kidID)
    }

    func test只显示本孩子与通用项() {
        let items = [
            item("小明的", kidID: a),
            item("小红的", kidID: b),
            item("通用的", kidID: nil)
        ]
        let titles = ItemFilter.visible(items, kidID: a).map(\.title)
        XCTAssertEqual(titles, ["小明的", "通用的"])
    }

    func test换孩子后看到另一组() {
        let items = [item("小明的", kidID: a), item("小红的", kidID: b)]
        XCTAssertEqual(ItemFilter.visible(items, kidID: b).map(\.title), ["小红的"])
    }

    /// 孩子还没加载出来时不能显示任何人的专属项，否则会闪一下另一个孩子的项目。
    func test没有选中孩子时只显示通用项() {
        let items = [item("小明的", kidID: a), item("小红的", kidID: b), item("通用的", kidID: nil)]
        XCTAssertEqual(ItemFilter.visible(items, kidID: nil).map(\.title), ["通用的"])
    }

    /// 老版本存的数据没有 kidID，迁移上来后仍要对两个孩子可见。
    func test老数据nil归属对两个人都可见() {
        let legacy = [item("老数据", kidID: nil)]
        XCTAssertEqual(ItemFilter.visible(legacy, kidID: a).count, 1)
        XCTAssertEqual(ItemFilter.visible(legacy, kidID: b).count, 1)
    }

    func test通用项不重复() {
        let items = [item("通用的", kidID: nil)]
        XCTAssertEqual(ItemFilter.visible(items, kidID: a).count, 1)
    }

    func test没有孩子时返回空() {
        XCTAssertTrue(ItemFilter.visible([item("x", kidID: a)], kidID: b).isEmpty)
    }
}
