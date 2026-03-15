import SwiftUI

@main
struct IcerockIntelligenceApp: App {
    @StateObject private var vm = BotViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .preferredColorScheme(.dark)
        }
    }
}
