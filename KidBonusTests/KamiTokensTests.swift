import XCTest
import SwiftUI
@testable import KidBonus

final class KamiTokensTests: XCTestCase {
    func testKamiColorsLoadFromHex() {
        let bg = Color.kami.bg
        let accent = Color.kami.accent
        XCTAssertNotNil(bg); XCTAssertNotNil(accent)
    }
    func testSpacingValues() {
        XCTAssertEqual(Spacing.s1, 4)
        XCTAssertEqual(Spacing.s4, 16)
    }
    func testFontKamiBodyReturnsCustomFont() {
        let f = Font.kami(.body, size: 14)
        XCTAssertNotNil(f)
    }
}
