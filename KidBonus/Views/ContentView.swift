import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var ctx
    @State private var toast = ToastCenter()
    @State private var showingStats = false

    var body: some View {
        ZStack(alignment: .top) {
            TabView {
                HomeView()
                    .tabItem { Label("首页", systemImage: "house") }
                QuickView()
                    .tabItem { Label("加减", systemImage: "plus") }
                ShopView()
                    .tabItem { Label("商城", systemImage: "bag") }
                HistoryView()
                    .tabItem { Label("历程", systemImage: "clock") }
                MeView()
                    .tabItem { Label("我的", systemImage: "person") }
            }
            .tint(.kami.accent)

            if let t = toast.current {
                ToastBanner(toast: t)
            }
        }
        .environment(toast)
        .sheet(isPresented: $showingStats) {
            StatsView()
        }
        .onAppear {
            SeedData.installIfEmpty(ctx: ctx)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Kid.self, PointItem.self, Product.self,
                              HistoryRecord.self, Redemption.self, Streak.self],
                        inMemory: true)
}
