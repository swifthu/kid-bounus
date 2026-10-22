import SwiftUI
import SwiftData

@main
struct KidBonusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let container: ModelContainer = {
        let schema = Schema([Kid.self, PointItem.self, Product.self, BonusRule.self,
                             HistoryRecord.self, Redemption.self, Streak.self])
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema)
    }()

    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.environment["DISABLE_SWIFTUI_IN_TESTS"] != nil {
                // Test harness: render nothing to avoid SwiftData query crashes during view init
                EmptyView()
            } else {
                ContentView()
                    .task { applyLaunchHooks() }
            }
        }
        .modelContainer(container)
    }

    /// 带 `-uitest-reset` 启动时先清空并重播种。
    /// UI 测试的各用例共用同一个模拟器与持久化 store，不重置会互相污染断言。
    private func applyLaunchHooks() {
        guard ProcessInfo.processInfo.arguments.contains("-uitest-reset") else { return }
        SeedData.installFresh(ctx: container.mainContext)
    }
}
