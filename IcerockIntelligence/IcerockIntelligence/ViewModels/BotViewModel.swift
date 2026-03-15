import Foundation
import SwiftUI

@MainActor
final class BotViewModel: ObservableObject {
    @Published var bots: [BotModel] = []
    @Published var dashboard: DashboardData?
    @Published var selectedBot: BotModel?

    @Published var trades: [TradeModel] = []
    @Published var decisions: [DecisionModel] = []
    @Published var metrics: [BotMetric] = []

    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedTab = 0

    @Published var showCreateSheet = false
    @Published var backtestInProgress: Set<Int> = []
    @Published var analyzeInProgress: Set<Int> = []

    private let api = APIService.shared

    // MARK: - Load

    func loadAll() async {
        isLoading = true
        error = nil
        do {
            async let botsTask = api.fetchBots()
            async let dashTask = api.fetchDashboard()
            let (b, d) = try await (botsTask, dashTask)
            bots = b
            dashboard = d
        } catch {
            self.error = "Сервер недоступен"
        }
        isLoading = false
    }

    func loadBotDetail(botId: Int) async {
        do {
            async let t = api.fetchTrades(botId: botId)
            async let d = api.fetchDecisions(botId: botId)
            async let m = api.fetchMetrics(botId: botId)
            let (tr, de, me) = try await (t, d, m)
            trades = tr
            decisions = de
            metrics = me
        } catch {
            self.error = "Ошибка загрузки данных бота"
        }
    }

    // MARK: - Actions

    func createBot(name: String, symbol: String, strategy: String, capital: Double) async {
        do {
            let bot = try await api.createBot(name: name, symbol: symbol, strategy: strategy, capital: capital)
            bots.insert(bot, at: 0)
        } catch {
            self.error = "Ошибка создания бота"
        }
    }

    func startBot(_ bot: BotModel) async {
        do {
            try await api.startBot(id: bot.id)
            await loadAll()
        } catch {
            self.error = "Ошибка запуска"
        }
    }

    func stopBot(_ bot: BotModel) async {
        do {
            try await api.stopBot(id: bot.id)
            await loadAll()
        } catch {
            self.error = "Ошибка остановки"
        }
    }

    func deleteBot(_ bot: BotModel) async {
        do {
            try await api.deleteBot(id: bot.id)
            bots.removeAll { $0.id == bot.id }
            if selectedBot?.id == bot.id { selectedBot = nil }
        } catch {
            self.error = "Ошибка удаления"
        }
    }

    func runBacktest(_ bot: BotModel) async {
        backtestInProgress.insert(bot.id)
        do {
            _ = try await api.runBacktest(botId: bot.id)
            await loadAll()
            if selectedBot?.id == bot.id {
                await loadBotDetail(botId: bot.id)
            }
        } catch {
            self.error = "Ошибка бэктеста"
        }
        backtestInProgress.remove(bot.id)
    }

    func analyzeBot(_ bot: BotModel) async {
        analyzeInProgress.insert(bot.id)
        do {
            _ = try await api.analyzeBot(botId: bot.id)
            await loadAll()
            if selectedBot?.id == bot.id {
                await loadBotDetail(botId: bot.id)
            }
        } catch {
            self.error = "Ошибка анализа"
        }
        analyzeInProgress.remove(bot.id)
    }
}
