import SwiftUI
import SwiftData

@main
struct KidBonusApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Kid.self, PointItem.self, Product.self,
            HistoryRecord.self, Redemption.self, Streak.self
        ])
    }
}
