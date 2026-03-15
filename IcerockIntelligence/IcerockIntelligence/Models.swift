import Foundation
import SwiftUI

// MARK: - API Response Models

struct BotMetric: Codable, Hashable, Sendable {
    let id: Int
    let botId: Int
    let equity: Double
    let pnl: Double
    let pnlPercent: Double
    let sharpe: Double
    let maxDrawdown: Double
    let winRate: Double
    let totalTrades: Int
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case id
        case botId = "bot_id"
        case equity, pnl
        case pnlPercent = "pnl_percent"
        case sharpe
        case maxDrawdown = "max_drawdown"
        case winRate = "win_rate"
        case totalTrades = "total_trades"
        case timestamp
    }
}

struct BotModel: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let symbol: String
    let strategy: String
    let status: String
    let initialCapital: Double
    let createdAt: String
    let latestMetric: BotMetric?

    enum CodingKeys: String, CodingKey {
        case id, name, symbol, strategy, status
        case initialCapital = "initial_capital"
        case createdAt = "created_at"
        case latestMetric = "latest_metric"
    }

    var statusEnum: BotStatusType {
        switch status {
        case "active": return .active
        case "analyzing": return .analyzing
        default: return .stopped
        }
    }

    var pnl: Double { latestMetric?.pnl ?? 0 }
    var equity: Double { latestMetric?.equity ?? initialCapital }
    var pnlPercent: Double { latestMetric?.pnlPercent ?? 0 }
    var isProfit: Bool { pnl >= 0 }
}

enum BotStatusType: String {
    case active, stopped, analyzing

    var color: Color {
        switch self {
        case .active: return .appGreen
        case .stopped: return .appRed
        case .analyzing: return .appBlue
        }
    }

    var label: String {
        switch self {
        case .active: return "Активен"
        case .stopped: return "Остановлен"
        case .analyzing: return "Анализ"
        }
    }

    var icon: String {
        switch self {
        case .active: return "bolt.fill"
        case .stopped: return "pause.fill"
        case .analyzing: return "brain.head.profile"
        }
    }
}

struct TradeModel: Codable, Identifiable, Sendable {
    let id: Int
    let botId: Int
    let side: String
    let symbol: String
    let price: Double
    let amount: Double
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case id
        case botId = "bot_id"
        case side, symbol, price, amount, timestamp
    }

    var isBuy: Bool { side == "buy" }
}

struct DecisionModel: Codable, Identifiable, Sendable {
    let id: Int
    let botId: Int
    let action: String
    let reasoning: String
    let confidence: Double
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case id
        case botId = "bot_id"
        case action, reasoning, confidence, timestamp
    }
}

struct DashboardData: Codable, Sendable {
    let totalBots: Int
    let activeBots: Int
    let totalEquity: Double
    let totalPnl: Double
    let avgSharpe: Double
    let bestBotName: String?
    let bestBotPnl: Double
    let equityHistory: [[String: AnyCodableValue]]

    enum CodingKeys: String, CodingKey {
        case totalBots = "total_bots"
        case activeBots = "active_bots"
        case totalEquity = "total_equity"
        case totalPnl = "total_pnl"
        case avgSharpe = "avg_sharpe"
        case bestBotName = "best_bot_name"
        case bestBotPnl = "best_bot_pnl"
        case equityHistory = "equity_history"
    }
}

struct BacktestResult: Codable, Sendable {
    let botId: Int
    let tradesCount: Int
    let finalEquity: Double
    let pnl: Double
    let pnlPercent: Double
    let sharpe: Double
    let maxDrawdown: Double
    let winRate: Double

    enum CodingKeys: String, CodingKey {
        case botId = "bot_id"
        case tradesCount = "trades_count"
        case finalEquity = "final_equity"
        case pnl
        case pnlPercent = "pnl_percent"
        case sharpe
        case maxDrawdown = "max_drawdown"
        case winRate = "win_rate"
    }
}

struct AnalyzeResult: Codable, Sendable {
    let botId: Int
    let action: String
    let reasoning: String
    let confidence: Double

    enum CodingKeys: String, CodingKey {
        case botId = "bot_id"
        case action, reasoning, confidence
    }
}

struct LogEntry: Identifiable, Sendable {
    let id = UUID()
    let botId: Int
    let message: String
    let timestamp: Date
}

// MARK: - AnyCodableValue for flexible JSON

enum AnyCodableValue: Codable, Hashable, Sendable {
    case string(String)
    case double(Double)
    case int(Int)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(String.self) { self = .string(v) }
        else if let v = try? container.decode(Double.self) { self = .double(v) }
        else if let v = try? container.decode(Int.self) { self = .int(v) }
        else if let v = try? container.decode(Bool.self) { self = .bool(v) }
        else { self = .null }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .null: try container.encodeNil()
        }
    }
}

// MARK: - Design System Colors

extension Color {
    static let appBackground    = Color(hex: "#080c14")
    static let appCard          = Color(hex: "#111828")
    static let appBorder        = Color(hex: "#1a2340")
    static let appAccent        = Color(hex: "#4f6ef7")
    static let appGreen         = Color(hex: "#34d399")
    static let appRed           = Color(hex: "#f87171")
    static let appGold          = Color(hex: "#fbbf24")
    static let appBlue          = Color(hex: "#60a5fa")
    static let appTextPrimary   = Color(hex: "#e8eaf6")
    static let appTextSecondary = Color(hex: "#6b7280")
    static let appTextDim       = Color(hex: "#2a3555")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8)*17, (int >> 4 & 0xF)*17, (int & 0xF)*17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Formatters

func formatCurrency(_ value: Double) -> String {
    let abs = Swift.abs(value)
    let sign = value >= 0 ? "+" : "-"
    if abs >= 1_000_000 { return "\(sign)$\(String(format: "%.1fM", abs / 1_000_000))" }
    if abs >= 1_000     { return "\(sign)$\(String(format: "%.1fK", abs / 1_000))" }
    return "\(sign)$\(String(format: "%.2f", abs))"
}

func formatPercent(_ value: Double) -> String {
    String(format: "%+.2f%%", value)
}

func strategyLabel(_ strategy: String) -> String {
    switch strategy {
    case "sma_crossover": return "SMA Crossover"
    case "momentum": return "Momentum"
    case "mean_reversion": return "Mean Reversion"
    default: return strategy.capitalized
    }
}
