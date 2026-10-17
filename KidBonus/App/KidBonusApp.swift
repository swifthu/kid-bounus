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

struct ContentView: View {
    @Environment(\.modelContext) private var ctx

    var body: some View {
        Text("KidBonus")
            .font(.system(size: 28, weight: .medium))
            .task {
                SeedData.installIfEmpty(ctx: ctx)
            }
    }
}
