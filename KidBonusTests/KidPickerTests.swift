import XCTest
@testable import KidBonus

final class KidPickerTests: XCTestCase {

    func test有效ID命中() {
        let a = UUID(), b = UUID()
        XCTAssertEqual(KidPicker.resolve(storedID: b.uuidString, availableIDs: [a, b]), b)
    }

    func test无效ID回退到首个() {
        let a = UUID()
        XCTAssertEqual(KidPicker.resolve(storedID: UUID().uuidString, availableIDs: [a]), a)
    }

    func test空存储ID回退到首个() {
        let a = UUID()
        XCTAssertEqual(KidPicker.resolve(storedID: "", availableIDs: [a]), a)
    }

    /// 回归：孩子列表为空时不能越界崩溃。
    func test空列表返回nil() {
        XCTAssertNil(KidPicker.resolve(storedID: UUID().uuidString, availableIDs: []))
        XCTAssertNil(KidPicker.resolve(storedID: "", availableIDs: []))
    }

    func test非法字符串不会崩溃() {
        let a = UUID()
        XCTAssertEqual(KidPicker.resolve(storedID: "not-a-uuid", availableIDs: [a]), a)
    }
}
