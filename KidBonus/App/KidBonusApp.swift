import SwiftUI
import SwiftData

@main
struct KidBonusApp: App {
    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.environment["DISABLE_SWIFTUI_IN_TESTS"] != nil {
                // Test harness: render nothing to avoid SwiftData query crashes during view init
                EmptyView()
            } else {
                ContentView()
            }
        }
        .modelContainer(for: [
            Kid.self, PointItem.self, Product.self,
            HistoryRecord.self, Redemption.self, Streak.self
        ])
    }
}
