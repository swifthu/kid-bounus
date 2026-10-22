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

    /// 不跟着系统字号缩放：头像这类固定尺寸的小圆片，文字放大了会被裁掉。
    static func kamiFixed(_ style: KamiFontStyle = .body, size: CGFloat) -> Font {
        switch style {
        case .display:
            return .custom("LXGWWenKai-Light", fixedSize: size)
        case .body:
            return .custom("LXGWWenKai-Regular", fixedSize: size)
        case .mono:
            return .system(size: size, design: .monospaced)
        }
    }
}
