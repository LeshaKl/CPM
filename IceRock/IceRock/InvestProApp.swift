import SwiftUI

@main
struct InvestProApp: App {
    @StateObject private var vm = PortfolioViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .preferredColorScheme(.dark)
        }
    }
}
