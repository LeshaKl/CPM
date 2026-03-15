import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var vm: BotViewModel
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        metricsGrid
                        botPerformanceRanking
                        strategyBreakdown
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
                }
            }
            .navigationTitle("Аналитика")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(hex: "#0c1020"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear { withAnimation(.easeOut(duration: 0.5)) { appeared = true } }
    }

    private var metricsGrid: some View {
        let dashboard = vm.dashboard
        let metrics: [(String, String, String, Color)] = [
            ("Σ", "Total Equity", String(format: "$%.0f", dashboard?.totalEquity ?? 0), .appAccent),
            ("Δ", "Total PnL", formatCurrency(dashboard?.totalPnl ?? 0),
             (dashboard?.totalPnl ?? 0) >= 0 ? .appGreen : .appRed),
            ("σ", "Avg Sharpe", String(format: "%.2f", dashboard?.avgSharpe ?? 0), .appGold),
            ("⊕", "Active Bots", "\(dashboard?.activeBots ?? 0)/\(dashboard?.totalBots ?? 0)", .appBlue),
        ]

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(Array(metrics.enumerated()), id: \.offset) { index, m in
                GlassCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(m.0)
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(m.3)
                        Text(m.1)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                        Text(m.2)
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(m.3)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.08), value: appeared)
            }
        }
    }

    private var botPerformanceRanking: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.appGold)
                        .font(.system(size: 14))
                    Text("Рейтинг ботов по PnL")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)

                let sorted = vm.bots.sorted { $0.pnl > $1.pnl }
                ForEach(Array(sorted.enumerated()), id: \.element.id) { index, bot in
                    HStack(spacing: 10) {
                        Text("#\(index + 1)")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(index == 0 ? .appGold : .appTextSecondary)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(bot.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.appTextPrimary)
                            Text(bot.symbol)
                                .font(.system(size: 10))
                                .foregroundColor(.appTextSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatCurrency(bot.pnl))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(bot.isProfit ? .appGreen : .appRed)
                            Text(formatPercent(bot.pnlPercent))
                                .font(.system(size: 10))
                                .foregroundColor(bot.isProfit ? .appGreen : .appRed)
                        }

                        GeometryReader { geo in
                            let maxPnl = sorted.first?.pnl ?? 1
                            let fraction = maxPnl > 0 ? abs(bot.pnl) / abs(maxPnl) : 0
                            RoundedRectangle(cornerRadius: 3)
                                .fill(bot.isProfit ? Color.appGreen.opacity(0.5) : Color.appRed.opacity(0.5))
                                .frame(width: geo.size.width * CGFloat(fraction), height: 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(width: 60, height: 6)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                }
                .padding(.bottom, 10)
            }
        }
    }

    private var strategyBreakdown: some View {
        let grouped = Dictionary(grouping: vm.bots, by: \.strategy)
        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.appAccent)
                    Text("Стратегии")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)

                ForEach(Array(grouped.keys.sorted()), id: \.self) { strategy in
                    let bots = grouped[strategy] ?? []
                    let totalPnl = bots.reduce(0.0) { $0 + $1.pnl }
                    HStack {
                        Text(strategyLabel(strategy))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.appTextPrimary)
                        Spacer()
                        Text("\(bots.count) бот(ов)")
                            .font(.system(size: 11))
                            .foregroundColor(.appTextSecondary)
                        Text(formatCurrency(totalPnl))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(totalPnl >= 0 ? .appGreen : .appRed)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                }
                .padding(.bottom, 10)
            }
        }
    }
}
