import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var ctx
    @State private var toast = ToastCenter()
    @State private var showingStats = false

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Text("成长树")
                    .font(.kami(.body, size: 13))
                    .foregroundStyle(Color.kami.meta)
                Spacer()
                Button { showingStats = true } label: {
                    Image(systemName: "chart.bar")
                        .foregroundStyle(Color.kami.muted)
                        .frame(width: 36, height: 36)
                }
                Button {
                    // Jump to "我的": TabView programmatic switch — iOS TabView limitation;
                    // handled in follow-up task; kept as noop placeholder here.
                } label: {
                    Image(systemName: "person")
                        .foregroundStyle(Color.kami.muted)
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s2)
            .background(Color.kami.bg)

            // TabView + toast overlay
            ZStack(alignment: .top) {
                TabView {
                    HomeView().tabItem { Label("首页", systemImage: "house") }
                    QuickView().tabItem { Label("加减", systemImage: "plus") }
                    ShopView().tabItem { Label("商城", systemImage: "bag") }
                    HistoryView().tabItem { Label("历程", systemImage: "clock") }
                    MeView().tabItem { Label("我的", systemImage: "person") }
                }
                .tint(.kami.accent)

                if let t = toast.current {
                    ToastBanner(toast: t)
                }
            }
        }
        .background(Color.kami.bg)
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
