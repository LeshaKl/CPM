import Foundation

final class APIService: Sendable {
    static let shared = APIService()

    private let baseURL = "http://127.0.0.1:8000"

    // MARK: - Bots

    func fetchBots() async throws -> [BotModel] {
        try await get("/bots")
    }

    func fetchBot(id: Int) async throws -> BotModel {
        try await get("/bots/\(id)")
    }

    func createBot(name: String, symbol: String, strategy: String, capital: Double) async throws -> BotModel {
        let body: [String: Any] = [
            "name": name, "symbol": symbol,
            "strategy": strategy, "initial_capital": capital,
        ]
        return try await post("/bots", body: body)
    }

    func startBot(id: Int) async throws {
        let _: [String: AnyCodableValue] = try await post("/bots/\(id)/start", body: [:])
    }

    func stopBot(id: Int) async throws {
        let _: [String: AnyCodableValue] = try await post("/bots/\(id)/stop", body: [:])
    }

    func deleteBot(id: Int) async throws {
        let _: [String: AnyCodableValue] = try await delete("/bots/\(id)")
    }

    // MARK: - Backtest & Analysis

    func runBacktest(botId: Int, period: String = "6mo") async throws -> BacktestResult {
        try await post("/bots/\(botId)/backtest?period=\(period)", body: [:])
    }

    func analyzeBot(botId: Int) async throws -> AnalyzeResult {
        try await post("/bots/\(botId)/analyze", body: [:])
    }

    // MARK: - Data

    func fetchTrades(botId: Int) async throws -> [TradeModel] {
        try await get("/bots/\(botId)/trades")
    }

    func fetchMetrics(botId: Int) async throws -> [BotMetric] {
        try await get("/bots/\(botId)/metrics")
    }

    func fetchDecisions(botId: Int) async throws -> [DecisionModel] {
        try await get("/bots/\(botId)/decisions")
    }

    func fetchDashboard() async throws -> DashboardData {
        try await get("/dashboard")
    }

    // MARK: - HTTP

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let url = URL(string: baseURL + path)!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        let url = URL(string: baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !body.isEmpty {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func delete<T: Decodable>(_ path: String) async throws -> T {
        let url = URL(string: baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
