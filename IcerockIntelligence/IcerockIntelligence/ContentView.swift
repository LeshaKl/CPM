import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: BotViewModel

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            #if os(iOS)
            TabView(selection: $vm.selectedTab) {
                HomeView()
                    .tabItem { Label("Главная", systemImage: "chart.pie.fill") }
                    .tag(0)

                BotsListView()
                    .tabItem { Label("Боты", systemImage: "cpu") }
                    .tag(1)

                AnalyticsView()
                    .tabItem { Label("Анализ", systemImage: "chart.bar.fill") }
                    .tag(2)

                SettingsView()
                    .tabItem { Label("Настройки", systemImage: "gearshape.fill") }
                    .tag(3)
            }
            .tint(Color.appAccent)
            .onAppear { configureTabBar() }
            #else
            NavigationSplitView {
                List(selection: $vm.selectedTab) {
                    Label("Главная", systemImage: "chart.pie.fill").tag(0)
                    Label("Боты", systemImage: "cpu").tag(1)
                    Label("Анализ", systemImage: "chart.bar.fill").tag(2)
                    Label("Настройки", systemImage: "gearshape.fill").tag(3)
                }
                .listStyle(.sidebar)
                .navigationTitle("Icerock")
            } detail: {
                switch vm.selectedTab {
                case 0: HomeView()
                case 1: BotsListView()
                case 2: AnalyticsView()
                case 3: SettingsView()
                default: HomeView()
                }
            }
            #endif
        }
    }

    #if os(iOS)
    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "#0c1020"))
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.appTextSecondary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.appTextSecondary)]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.appAccent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.appAccent)]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    #endif
}
