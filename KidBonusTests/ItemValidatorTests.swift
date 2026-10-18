import XCTest
@testable import KidBonus

/// L1 纯逻辑：输入校验与符号归一化。
final class ItemValidatorTests: XCTestCase {

    func test正常加分项() throws {
        let draft = try ItemValidator.validate(kind: .add, title: "练琴", deltaText: "8", descText: "主动练习")
        XCTAssertEqual(draft.title, "练琴")
        XCTAssertEqual(draft.delta, 8)
        XCTAssertEqual(draft.desc, "主动练习")
    }

    func test空标题被拒绝() {
        XCTAssertThrowsError(try ItemValidator.validate(kind: .add, title: "", deltaText: "5", descText: "")) { error in
            XCTAssertEqual(error as? ItemValidationError, .emptyTitle)
        }
    }

    func test纯空格标题被拒绝() {
        XCTAssertThrowsError(try ItemValidator.validate(kind: .add, title: "   \n ", deltaText: "5", descText: "")) { error in
            XCTAssertEqual(error as? ItemValidationError, .emptyTitle)
        }
    }

    func test零分值被拒绝() {
        XCTAssertThrowsError(try ItemValidator.validate(kind: .add, title: "x", deltaText: "0", descText: "")) { error in
            XCTAssertEqual(error as? ItemValidationError, .invalidDelta)
        }
    }

    func test非数字分值被拒绝() {
        XCTAssertThrowsError(try ItemValidator.validate(kind: .add, title: "x", deltaText: "abc", descText: "")) { error in
            XCTAssertEqual(error as? ItemValidationError, .invalidDelta)
        }
    }

    /// 用户在「加分项」里输入负数，应纠正为正。
    func test加分项负分被纠正为正() throws {
        let draft = try ItemValidator.validate(kind: .add, title: "x", deltaText: "-5", descText: "")
        XCTAssertEqual(draft.delta, 5)
    }

    /// 用户在「扣分项」里输入正数，应纠正为负。
    func test扣分项正分被纠正为负() throws {
        let draft = try ItemValidator.validate(kind: .deduct, title: "x", deltaText: "5", descText: "")
        XCTAssertEqual(draft.delta, -5)
    }

    func test扣分项负分保持不变() throws {
        let draft = try ItemValidator.validate(kind: .deduct, title: "x", deltaText: "-3", descText: "")
        XCTAssertEqual(draft.delta, -3)
    }

    func test加分项空描述用默认文案() throws {
        let draft = try ItemValidator.validate(kind: .add, title: "x", deltaText: "5", descText: "")
        XCTAssertEqual(draft.desc, "一个好习惯")
    }

    func test扣分项空描述用默认文案() throws {
        let draft = try ItemValidator.validate(kind: .deduct, title: "x", deltaText: "5", descText: "")
        XCTAssertEqual(draft.desc, "需要改进的小事")
    }

    func test空白描述等同空描述() throws {
        let draft = try ItemValidator.validate(kind: .add, title: "x", deltaText: "5", descText: "   ")
        XCTAssertEqual(draft.desc, "一个好习惯")
    }

    func test标题与分值两端空白被去除() throws {
        let draft = try ItemValidator.validate(kind: .add, title: "  练琴  ", deltaText: " 8 ", descText: "")
        XCTAssertEqual(draft.title, "练琴")
        XCTAssertEqual(draft.delta, 8)
    }

    func test默认图标() {
        XCTAssertEqual(ItemValidator.defaultIconName(for: .add), "checkmark")
        XCTAssertEqual(ItemValidator.defaultIconName(for: .deduct), "exclamationmark")
    }
}
