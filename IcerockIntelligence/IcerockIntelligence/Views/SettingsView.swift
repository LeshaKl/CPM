import SwiftUI
import Combine

struct SettingsView: View {
    @EnvironmentObject var vm: BotViewModel
    @AppStorage("apiBaseURL") private var apiBaseURL = "http://127.0.0.1:8000"
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                List {
                    Section("Подключение") {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("API Server URL", systemImage: "server.rack")
                                .foregroundColor(.appTextPrimary)
                                .font(.system(size: 13, weight: .semibold))
                            TextField("http://127.0.0.1:8000", text: $apiBaseURL)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.appAccent)
                                .tint(.appAccent)
                        }

                        Button {
                            Task {
                                await vm.loadAll()
                                showAlert = true
                            }
                        } label: {
                            Label("Проверить подключение", systemImage: "antenna.radiowaves.left.and.right")
                                .foregroundColor(.appAccent)
                        }
                    }

                    Section("Система") {
                        settingsRow("cpu", "Ботов создано", "\(vm.bots.count)")
                        settingsRow("bolt.fill", "Активных", "\(vm.bots.filter { $0.status == "active" }.count)")
                        settingsRow("brain", "AI Agent", "Groq LLaMA 3.3")
                        settingsRow("chart.bar.fill", "Backtest Engine", "yfinance + SMA/Mom/MR")
                    }

                    Section("О приложении") {
                        settingsRow("info.circle.fill", "Версия", "1.0.0")
                        settingsRow("brain.head.profile", "Icerock Intelligence", "HSE VibeHACK 2026")
                        settingsRow("person.3.fill", "Команда", "C+-")
                    }

                    Section("Данные") {
                        Button(role: .destructive) {
                            Task {
                                for bot in vm.bots {
                                    await vm.deleteBot(bot)
                                }
                            }
                        } label: {
                            Label("Удалить всех ботов", systemImage: "trash.fill")
                                .foregroundColor(.appRed)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.appBackground)
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(hex: "#0c1020"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Подключение", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text(vm.error == nil ? "Сервер доступен" : "Сервер недоступен: \(vm.error ?? "")")
            }
        }
    }

    private func settingsRow(_ icon: String, _ title: String, _ value: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundColor(.appTextPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(.appTextSecondary)
        }
    }
}
