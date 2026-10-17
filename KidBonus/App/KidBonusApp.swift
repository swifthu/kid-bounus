import SwiftUI

@main
struct KidBonusApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        Text("KidBonus")
            .font(.system(size: 28, weight: .medium))
    }
}
