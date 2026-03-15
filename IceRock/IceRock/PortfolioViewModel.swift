import Foundation
import Combine
import SwiftUI

final class PortfolioViewModel: ObservableObject {
    @Published var assets: [Asset]         = []
    @Published var news: [NewsItem]        = []
    @Published var dividends: [DividendEvent] = []
    @Published var screener: [ScreenerRow] = []

    @Published var selectedTab: Int = 0
    @Published var selectedAsset: Asset? = nil
    @Published var isDark: Bool = true

    let totalBalance: Double = 2_497_381_644
    let yieldPercent: String = "+14.73%"
    let riskIndex: Double    = 2.34

    private var timer: AnyCancellable?

    init() {
        assets    = DataService.generateAssets()
        news      = DataService.generateNews()
        dividends = DataService.generateDividends()
        screener  = DataService.generateScreener()
        startLiveTicker()
    }

    var totalValue: Double { assets.reduce(0) { $0 + $1.positionValue } }
    var totalProfit: Double { assets.reduce(0) { $0 + $1.profit } }

    func pieSlices() -> [(asset: Asset, fraction: Double, color: Color)] {
        let total = assets.reduce(0.0) { $0 + $1.positionValue }
        guard total > 0 else { return [] }
        return assets.map { a in
            (asset: a, fraction: a.positionValue / total, color: sectorColor(a.sector))
        }
    }

    func allocationBySector() -> [(sector: String, fraction: Double, color: Color)] {
        var map: [String: Double] = [:]
        let total = assets.reduce(0.0) { $0 + $1.positionValue }
        guard total > 0 else { return [] }
        for a in assets { map[a.sector, default: 0] += a.positionValue }
        return map.map { (sector: $0.key, fraction: $0.value / total, color: sectorColor($0.key)) }
                  .sorted { $0.fraction > $1.fraction }
    }

    private func startLiveTicker() {
        timer = Timer.publish(every: 3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        for i in assets.indices {
            let delta = Double.random(in: -0.004...0.004) * assets[i].currentPrice
            assets[i].prevPrice    = assets[i].currentPrice
            assets[i].currentPrice += delta
        }
    }
}
