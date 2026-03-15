import SwiftUI
#if os(iOS)
import UIKit
#endif

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
