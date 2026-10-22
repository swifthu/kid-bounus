import SwiftUI
import SwiftData

struct ContentView: View {
    /// TabView 中「我的」的下标，供顶栏按钮跳转。
    private static let meTabIndex = 4

    @Environment(\.modelContext) private var ctx
    @State private var toast = ToastCenter()
    @State private var showingStats = false
    /// tab 放在 router 里，主屏长按图标的快捷操作才能切页
    @State private var router = AppRouter.shared

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
                    router.tab = Self.meTabIndex
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
                TabView(selection: $router.tab) {
                    HomeView().tabItem { Label("首页", systemImage: "house") }.tag(0)
                    QuickView().tabItem { Label("加减", systemImage: "plus") }.tag(1)
                    ShopView().tabItem { Label("商城", systemImage: "bag") }.tag(2)
                    HistoryView().tabItem { Label("历程", systemImage: "clock") }.tag(3)
                    MeView().tabItem { Label("我的", systemImage: "person") }.tag(Self.meTabIndex)
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
        .modelContainer(for: [Kid.self, PointItem.self, Product.self, BonusRule.self,
                              HistoryRecord.self, Redemption.self, Streak.self],
                        inMemory: true)
}
