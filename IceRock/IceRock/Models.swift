import Foundation
import SwiftUI

struct CandleData: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int
    var isBullish: Bool { close >= open }
}

struct Asset: Identifiable, Hashable {
    let id = UUID()
    let ticker: String
    let name: String
    let sector: String
    let tickCount: Int
    let avgPrice: Double
    var currentPrice: Double
    var prevPrice: Double 
    var profit: Double { (currentPrice - avgPrice) * Double(tickCount) }
    let personalRisk: Double
    let candles: [CandleData]

    var changePercent: Double {
        guard prevPrice > 0 else { return 0 }
        return (currentPrice - prevPrice) / prevPrice * 100.0
    }
    var isUp: Bool { currentPrice >= prevPrice }
    var positionValue: Double { currentPrice * Double(tickCount) }
}

extension Asset: Equatable {
    static func == (lhs: Asset, rhs: Asset) -> Bool {
        lhs.id == rhs.id && lhs.ticker == rhs.ticker && lhs.name == rhs.name
    }
}

struct NewsItem: Identifiable {
    let id = UUID()
    let source: String
    let title: String
    let body: String
    let relatedTicker: String
    let date: Date
}

struct DividendEvent: Identifiable {
    let id = UUID()
    let ticker: String
    let company: String
    let date: String
    let amount: String
    let yield: String
}

struct ScreenerRow: Identifiable {
    let id = UUID()
    let ticker: String
    let name: String
    let pe: Double
    let divYield: Double
    let roe: Double
    let beta: Double
    let cap: Double
}

extension Color {
    static let appBackground   = Color(hex: "#080c14")
    static let appCard         = Color(hex: "#111828")
    static let appBorder       = Color(hex: "#1a2340")
    static let appAccent       = Color(hex: "#4f6ef7")
    static let appGreen        = Color(hex: "#34d399")
    static let appRed          = Color(hex: "#f87171")
    static let appGold         = Color(hex: "#fbbf24")
    static let appBlue         = Color(hex: "#60a5fa")
    static let appTextPrimary  = Color(hex: "#e8eaf6")
    static let appTextSecondary = Color(hex: "#6b7280")
    static let appTextDim      = Color(hex: "#2a3555")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8)*17, (int >> 4 & 0xF)*17, (int & 0xF)*17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r)/255, green: Double(g)/255,
                  blue: Double(b)/255, opacity: Double(a)/255)
    }
}

func sectorColor(_ sector: String) -> Color {
    switch sector {
    case "Финансы":    return Color(hex: "#4f6ef7")
    case "Энергетика": return Color(hex: "#f59e0b")
    case "Нефть/газ":  return Color(hex: "#f97316")
    case "Технологии": return Color(hex: "#8b5cf6")
    case "Металлы":    return Color(hex: "#6b7280")
    case "Сырьё":      return Color(hex: "#fbbf24")
    case "Валюта":     return Color(hex: "#06b6d4")
    case "Облигации":  return Color(hex: "#34d399")
    case "Ритейл":     return Color(hex: "#ec4899")
    default:           return Color(hex: "#4b5563")
    }
}

func shortFmt(_ v: Double) -> String {
    let neg = v < 0
    let abs = Swift.abs(v)
    let s: String
    if abs >= 1e9      { s = String(format: "%.2f млрд", abs/1e9) }
    else if abs >= 1e6 { s = String(format: "%.1f млн",  abs/1e6) }
    else if abs >= 1e3 { s = String(format: "%.1f тыс",  abs/1e3) }
    else               { s = String(format: "%.2f",       abs)     }
    return (neg ? "−" : "+") + s
}

func fmtRub(_ v: Double) -> String { shortFmt(v) + " ₽" }

