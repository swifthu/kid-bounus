import SwiftUI

/// 按下时给一点反馈：缩一点、稍微压暗。
/// 之前所有条目都是 plain 按钮样式，按下去完全没有视觉变化，
/// 孩子点了不知道到底点没点上。
struct PressStyle: ButtonStyle {
    /// 按下时的缩放。太小看不出来，太大会显得糊。
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressStyle {
    static var kamiPress: PressStyle { PressStyle() }
}