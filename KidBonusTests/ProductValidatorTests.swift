import XCTest
@testable import KidBonus

/// L1 纯逻辑：商品表单的输入校验与归一化。
final class ProductValidatorTests: XCTestCase {

    private func validate(name: String = "乐高积木", cost: String = "200",
                          icon: String = "", desc: String = "") throws -> ProductDraft {
        try ProductValidator.validate(name: name, costText: cost, category: .toy,
                                      iconText: icon, descText: desc)
    }

    func test正常商品() throws {
        let draft = try validate(desc: "小颗粒拼装玩具")
        XCTAssertEqual(draft.name, "乐高积木")
        XCTAssertEqual(draft.cost, 200)
        XCTAssertEqual(draft.category, .toy)
        XCTAssertEqual(draft.desc, "小颗粒拼装玩具")
    }

    func test空名称被拒绝() {
        XCTAssertThrowsError(try validate(name: "")) { error in
            XCTAssertEqual(error as? ProductValidationError, .emptyName)
        }
    }

    func test纯空格名称被拒绝() {
        XCTAssertThrowsError(try validate(name: "  \n ")) { error in
            XCTAssertEqual(error as? ProductValidationError, .emptyName)
        }
    }

    /// 0 分的商品谁都买得起，等于白送。
    func test零分值被拒绝() {
        XCTAssertThrowsError(try validate(cost: "0")) { error in
            XCTAssertEqual(error as? ProductValidationError, .invalidCost)
        }
    }

    func test负分值被拒绝() {
        XCTAssertThrowsError(try validate(cost: "-50")) { error in
            XCTAssertEqual(error as? ProductValidationError, .invalidCost)
        }
    }

    func test非数字分值被拒绝() {
        XCTAssertThrowsError(try validate(cost: "abc")) { error in
            XCTAssertEqual(error as? ProductValidationError, .invalidCost)
        }
    }

    func test空图标为nil由卡片回退() throws {
        XCTAssertNil(try validate(icon: "   ").iconName)
    }

    func test图标名两端空白被去除() throws {
        XCTAssertEqual(try validate(icon: "  book  ").iconName, "book")
    }

    func test空说明用默认文案() throws {
        XCTAssertEqual(try validate(desc: "  ").desc, "兑换奖励")
    }

    func test名称与分值两端空白被去除() throws {
        let draft = try validate(name: "  冰淇淋 ", cost: " 30 ")
        XCTAssertEqual(draft.name, "冰淇淋")
        XCTAssertEqual(draft.cost, 30)
    }
}
