import SwiftUI

extension Font {
    static func kami(_ style: KamiFontStyle = .body, size: CGFloat) -> Font {
        switch style {
        case .display:
            return .custom("LXGWWenKai-Light", size: size, relativeTo: .body)
        case .body:
            return .custom("LXGWWenKai-Regular", size: size, relativeTo: .body)
        case .mono:
            return .system(size: size, design: .monospaced)
        }
    }
}
