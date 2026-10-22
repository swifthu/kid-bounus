import UIKit

/// 主屏长按 App 图标弹出的快捷操作。
/// 走 UIApplicationShortcutItems：老但稳定，入口就是 iOS 约定的长按菜单。
final class AppDelegate: NSObject, UIApplicationDelegate {
    static let quickType = "com.kidbonus.growingtree.quick"
    static let manualType = "com.kidbonus.growingtree.manual"
    static let shopType = "com.kidbonus.growingtree.shop"

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.shortcutItems = Self.makeShortcutItems()
        return true
    }

    /// 快捷操作条目单独抽出来，方便测试直接断言。
    static func makeShortcutItems() -> [UIApplicationShortcutItem] {
        [
            UIApplicationShortcutItem(
                type: quickType,
                localizedTitle: "加减分",
                localizedSubtitle: "给当前孩子记一笔",
                icon: UIApplicationShortcutIcon(systemImageName: "plus.circle"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: manualType,
                localizedTitle: "记一笔",
                localizedSubtitle: "临时事项，标题和分值自己填",
                icon: UIApplicationShortcutIcon(systemImageName: "pencil.circle"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: shopType,
                localizedTitle: "积分商城",
                localizedSubtitle: "看看能换什么",
                icon: UIApplicationShortcutIcon(systemImageName: "bag.circle"),
                userInfo: nil
            )
        ]
    }

    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        Task { @MainActor in
            let router = AppRouter.shared
            switch shortcutItem.type {
            case Self.quickType:
                router.tab = 1
            case Self.manualType:
                router.tab = 1
                router.pending = .manual
            case Self.shopType:
                router.tab = 2
            default:
                break
            }
            completionHandler(true)
        }
    }
}
