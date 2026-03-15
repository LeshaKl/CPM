import SwiftUI

struct BotDetailView: View {
    @EnvironmentObject var vm: BotViewModel
    @StateObject private var wsManager = WebSocketManager()
    let bot: BotModel

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    detailHeader
                    actionButtons
                    kpiStrip
                    equitySection
                    tradesSection
                    aiReasoningSection
                    LogView(wsManager: wsManager, botId: bot.id)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)
            }
        }
        .navigationTitle(bot.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: "#0c1020"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await vm.loadBotDetail(botId: bot.id) }
        .onAppear { withAnimation(.easeOut(duration: 0.5)) { appeared = true } }
    }

    // MARK: - Header

    private var detailHeader: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    bot.statusEnum.color
                    Image(systemName: bot.statusEnum.icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(bot.name)
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.appTextPrimary)
                    HStack(spacing: 6) {
                        Text(bot.symbol)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.appBlue)
                        Text(strategyLabel(bot.strategy))
                            .font(.system(size: 10))
                            .foregroundColor(.appTextSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appBorder)
                            .clipShape(Capsule())
                        StatusBadge(status: bot.statusEnum)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(bot.pnl))
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(bot.isProfit ? .appGreen : .appRed)
                    Text(formatPercent(bot.pnlPercent))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(bot.isProfit ? .appGreen : .appRed)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: 8) {
            ActionButton(icon: "play.fill", label: "Start", color: .appGreen) {
                Task { await vm.startBot(bot) }
            }
            ActionButton(icon: "stop.fill", label: "Stop", color: .appRed) {
                Task { await vm.stopBot(bot) }
            }
            ActionButton(icon: "chart.bar.fill", label: "Backtest",
                         color: .appAccent,
                         isLoading: vm.backtestInProgress.contains(bot.id)) {
                Task { await vm.runBacktest(bot) }
            }
            ActionButton(icon: "brain", label: "AI Analyze",
                         color: .appGold,
                         isLoading: vm.analyzeInProgress.contains(bot.id)) {
                Task { await vm.analyzeBot(bot) }
            }
        }
    }

    // MARK: - KPI

    private var kpiStrip: some View {
        let metric = bot.latestMetric
        let items: [(String, String, Color)] = [
            ("Equity", String(format: "$%.0f", metric?.equity ?? bot.initialCapital), .appTextPrimary),
            ("Sharpe", String(format: "%.2f", metric?.sharpe ?? 0), .appGold),
            ("Win Rate", String(format: "%.0f%%", metric?.winRate ?? 0), .appGreen),
            ("Drawdown", String(format: "%.1f%%", metric?.maxDrawdown ?? 0), .appRed),
            ("Trades", "\(metric?.totalTrades ?? 0)", .appBlue),
            ("Capital", String(format: "$%.0f", bot.initialCapital), .appTextSecondary),
        ]

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                VStack(spacing: 4) {
                    Text(item.0)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                        .textCase(.uppercase)
                    Text(item.1)
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(item.2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
            }
        }
    }

    // MARK: - Equity

    private var equitySection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundColor(.appAccent)
                    Text("Equity Curve")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                if vm.metrics.count > 1 {
                    let values = vm.metrics.reversed().map(\.equity)
                    EquityChartView(values: Array(values), labels: [])
                        .frame(height: 200)
                        .padding(.horizontal, 8)
                } else {
                    Text("Запустите бэктест для отображения")
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                        .frame(maxWidth: .infinity, minHeight: 80)
                }
            }
            .padding(.bottom, 12)
        }
    }

    // MARK: - Trades

    private var tradesSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(.appBlue)
                    Text("Последние сделки")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                    Text("\(vm.trades.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.appTextSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                if vm.trades.isEmpty {
                    Text("Нет сделок")
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 12)
                } else {
                    ForEach(vm.trades.prefix(10)) { trade in
                        HStack(spacing: 10) {
                            Image(systemName: trade.isBuy ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .foregroundColor(trade.isBuy ? .appGreen : .appRed)
                                .font(.system(size: 16))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(trade.side.uppercased())
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(trade.isBuy ? .appGreen : .appRed)
                                Text(trade.symbol)
                                    .font(.system(size: 10))
                                    .foregroundColor(.appTextSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "$%.2f", trade.price))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.appTextPrimary)
                                Text(String(format: "%.4f", trade.amount))
                                    .font(.system(size: 10))
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)

                        if trade.id != vm.trades.prefix(10).last?.id {
                            Divider().background(Color.appBorder).padding(.horizontal, 14)
                        }
                    }
                    .padding(.bottom, 10)
                }
            }
        }
    }

    // MARK: - AI Reasoning

    private var aiReasoningSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.appGold)
                    Text("AI Reasoning Log")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                if vm.decisions.isEmpty {
                    Text("Запустите AI анализ для получения рекомендаций")
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 12)
                } else {
                    ForEach(vm.decisions.prefix(5)) { decision in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(decision.action.uppercased())
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(actionColor(decision.action))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(actionColor(decision.action).opacity(0.12))
                                    .clipShape(Capsule())

                                Spacer()

                                HStack(spacing: 4) {
                                    Text("Confidence:")
                                        .font(.system(size: 9))
                                        .foregroundColor(.appTextSecondary)
                                    Text(String(format: "%.0f%%", decision.confidence * 100))
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.appGold)
                                }
                            }

                            Text(decision.reasoning)
                                .font(.system(size: 12))
                                .foregroundColor(.appTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)

                        if decision.id != vm.decisions.prefix(5).last?.id {
                            Divider().background(Color.appBorder).padding(.horizontal, 14)
                        }
                    }
                    .padding(.bottom, 10)
                }
            }
        }
    }

    private func actionColor(_ action: String) -> Color {
        switch action {
        case "increase_position": return .appGreen
        case "decrease_position", "stop": return .appRed
        case "rebalance": return .appGold
        default: return .appBlue
        }
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(color)
                        .frame(height: 18)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(color)
                }
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.appTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.2), lineWidth: 1))
        }
        .disabled(isLoading)
    }
}
