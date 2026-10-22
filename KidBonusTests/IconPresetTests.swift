import XCTest
import UIKit
@testable import KidBonus

/// 预设图标：数量够用，且每个名字都真的对应一个 SF Symbol。
final class IconPresetTests: XCTestCase {
    func test图标数量至少30个() {
        XCTAssertGreaterThanOrEqual(IconPreset.all.count, 30)
    }

    func test图标不重复() {
        XCTAssertEqual(Set(IconPreset.all).count, IconPreset.all.count)
    }

    /// 名字写错的话系统会画成空白方块，这里逐个查一遍。
    func test每个图标都存在() {
        for name in IconPreset.all {
            XCTAssertNotNil(UIImage(systemName: name), "SF Symbol 不存在：\(name)")
        }
    }
}
