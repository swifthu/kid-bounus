import SwiftUI

/// 跨页面跳转的中枢。主屏长按图标的快捷操作也要能切 tab，所以放在 App 级别。
@MainActor
@Observable
final class AppRouter {
    static let shared = AppRouter()

    /// 当前选中的 tab，顺序和 ContentView 里的 TabView 一致
    var tab: Int = 0

    /// 视图监听到后自己响应，处理完要清空
    var pending: Request? = nil

    enum Request: Equatable {
        case manual   // 打开「手动加减分」
    }
}
