import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var vm: PortfolioViewModel

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            TabView(selection: $vm.selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Главная", systemImage: "chart.pie.fill")
                    }
                    .tag(0)

                AssetsView()
                    .tabItem {
                        Label("Активы", systemImage: "list.bullet.rectangle.fill")
                    }
                    .tag(1)

                NewsView()
                    .tabItem {
                        Label("Новости", systemImage: "newspaper.fill")
                    }
                    .tag(2)

                AnalyticsView()
                    .tabItem {
                        Label("Анализ", systemImage: "chart.bar.fill")
                    }
                    .tag(3)

                MoreView()
                    .tabItem {
                        Label("Ещё", systemImage: "ellipsis.circle.fill")
                    }
                    .tag(4)
            }
            .tint(Color.appAccent)
            .onAppear { configureTabBar() }
        }
    }

    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "#0c1020"))
        appearance.stackedLayoutAppearance.normal.iconColor   = UIColor(Color.appTextSecondary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes   = [.foregroundColor: UIColor(Color.appTextSecondary)]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.appAccent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.appAccent)]
        UITabBar.appearance().standardAppearance  = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
