import SwiftUI

struct HomeView: View {
    @EnvironmentObject var vm: BotViewModel
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        heroCard
                        kpiRow
                        equitySection
                        systemHealthCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.appAccent)
                            .font(.system(size: 16, weight: .bold))
                        Text("Icerock Intelligence")
                            .font(.system(size: 17, weight: .black))
                            .foregroundColor(.appAccent)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await vm.loadAll() } } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
            .toolbarBackground(Color(hex: "#0c1020"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .task { await vm.loadAll() }
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { appeared = true } }
    }

    // MARK: - Hero

    private var heroCard: some View {
        GlassCard {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    ZStack {
                        LinearGradient(colors: [Color(hex: "#4f6ef7"), Color(hex: "#8b5cf6")],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Icerock Intelligence")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.appTextPrimary)
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.appAccent)
                            Text("AI Trading System")
                                .font(.system(size: 11))
                                .foregroundColor(.appAccent)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider().background(Color.appBorder)

                HStack(spacing: 0) {
                    StatMini(title: "Доходность",
                             value: formatPercent(vm.dashboard?.totalPnl ?? 0 > 0
                                                  ? (vm.dashboard?.totalPnl ?? 0) / max(vm.dashboard?.totalEquity ?? 1, 1) * 100 : 0),
                             color: (vm.dashboard?.totalPnl ?? 0) >= 0 ? .appGreen : .appRed)
                    Divider().background(Color.appBorder).frame(height: 36)
                    StatMini(title: "Ботов", value: "\(vm.dashboard?.totalBots ?? 0)", color: .appBlue)
                    Divider().background(Color.appBorder).frame(height: 36)
                    StatMini(title: "Активных", value: "\(vm.dashboard?.activeBots ?? 0)", color: .appGreen)
                }
                .padding(.vertical, 10)

                Divider().background(Color.appBorder)

                VStack(spacing: 2) {
                    Text("Совокупный капитал")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                    Text(formatCurrency(vm.dashboard?.totalEquity ?? 0).replacingOccurrences(of: "+", with: ""))
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: Color.appAccent.opacity(0.4), radius: 8)
                }
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - KPI

    private var kpiRow: some View {
        let dashboard = vm.dashboard
        let kpis: [(String, String, String, Color)] = [
            ("chart.line.uptrend.xyaxis", "Total PnL", formatCurrency(dashboard?.totalPnl ?? 0),
             (dashboard?.totalPnl ?? 0) >= 0 ? .appGreen : .appRed),
            ("star.fill", "Avg Sharpe", String(format: "%.2f", dashboard?.avgSharpe ?? 0), .appGold),
            ("trophy.fill", "Best Bot", dashboard?.bestBotName ?? "—", .appBlue),
            ("dollarsign.circle.fill", "Best PnL", formatCurrency(dashboard?.bestBotPnl ?? 0), .appGreen),
        ]

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(Array(kpis.enumerated()), id: \.offset) { _, kpi in
                GlassCard {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: kpi.0)
                                .font(.system(size: 14))
                                .foregroundColor(kpi.3)
                            Text(kpi.1)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.appTextSecondary)
                        }
                        Text(kpi.2)
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(kpi.3)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Equity Chart

    private var equitySection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundColor(.appAccent)
                    Text("Equity Overview")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                if let history = vm.dashboard?.equityHistory, !history.isEmpty {
                    let values = history.compactMap { entry -> Double? in
                        if case .double(let v) = entry["equity"] { return v }
                        return nil
                    }
                    if values.count > 1 {
                        EquityChartView(values: values, labels: [])
                            .frame(height: 200)
                            .padding(.horizontal, 8)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 32))
                            .foregroundColor(.appTextDim)
                        Text("Запустите бэктест для отображения графика")
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                }
            }
            .padding(.bottom, 12)
        }
    }

    // MARK: - System Health

    private var systemHealthCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .foregroundColor(.appGreen)
                    Text("System Health")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    HealthPill(icon: "server.rack", label: "API", status: vm.error == nil ? "Online" : "Offline",
                               color: vm.error == nil ? .appGreen : .appRed)
                    HealthPill(icon: "cpu", label: "Engine", status: "Ready", color: .appGreen)
                    HealthPill(icon: "brain", label: "AI Agent", status: "Ready", color: .appBlue)
                }
            }
            .padding(14)
        }
    }
}

struct StatMini: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 14, weight: .black))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HealthPill: View {
    let icon: String
    let label: String
    let status: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.appTextSecondary)
            Text(status)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(color)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
