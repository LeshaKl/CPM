import SwiftUI

struct BotsListView: View {
    @EnvironmentObject var vm: BotViewModel
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    if vm.bots.isEmpty && !vm.isLoading {
                        emptyState
                    } else {
                        botsList
                    }
                }
            }
            .navigationTitle("Боты")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(hex: "#0c1020"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { vm.showCreateSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.appAccent)
                    }
                }
            }
            .sheet(isPresented: $vm.showCreateSheet) { CreateBotSheet() }
            .navigationDestination(for: BotModel.self) { bot in
                BotDetailView(bot: bot)
            }
        }
        .task { await vm.loadAll() }
        .onAppear { withAnimation(.easeOut(duration: 0.5)) { appeared = true } }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cpu")
                .font(.system(size: 48))
                .foregroundColor(.appTextDim)
            Text("Нет ботов")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.appTextSecondary)
            Text("Создайте первого бота для начала работы")
                .font(.system(size: 13))
                .foregroundColor(.appTextDim)
            Button { vm.showCreateSheet = true } label: {
                Label("Создать бота", systemImage: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.appAccent)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var botsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(Array(vm.bots.enumerated()), id: \.element.id) { index, bot in
                    NavigationLink(value: bot) {
                        BotRowCard(bot: bot)
                    }
                    .buttonStyle(.plain)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.06), value: appeared)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
    }
}

struct BotRowCard: View {
    let bot: BotModel

    private var sparkValues: [Double] {
        let base = bot.equity
        return (0..<20).map { i in
            base * (1.0 + sin(Double(i) * 0.4 + Double(bot.id)) * 0.03)
        }
    }

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                ZStack {
                    bot.statusEnum.color.opacity(0.2)
                    Image(systemName: bot.statusEnum.icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(bot.statusEnum.color)
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(bot.name)
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.appTextPrimary)
                        StatusBadge(status: bot.statusEnum)
                    }
                    HStack(spacing: 6) {
                        Text(bot.symbol)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.appBlue)
                        Text(strategyLabel(bot.strategy))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appBorder)
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                MiniChartView(values: sparkValues, isPositive: bot.isProfit)
                    .frame(width: 60, height: 30)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(formatCurrency(bot.pnl))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(bot.isProfit ? .appGreen : .appRed)
                    Text(formatPercent(bot.pnlPercent))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(bot.isProfit ? .appGreen : .appRed)
                }
                .frame(width: 80, alignment: .trailing)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }
}

struct CreateBotSheet: View {
    @EnvironmentObject var vm: BotViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var symbol = "AAPL"
    @State private var strategy = "sma_crossover"
    @State private var capital = "10000"

    let strategies = ["sma_crossover", "momentum", "mean_reversion"]
    let popularSymbols = ["AAPL", "GOOGL", "MSFT", "TSLA", "AMZN", "NVDA", "META", "SPY", "SBER.ME", "GAZP.ME"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        inputField("Имя бота", text: $name, icon: "cpu")
                        inputField("Тикер", text: $symbol, icon: "chart.bar")

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Популярные тикеры")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.appTextSecondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(popularSymbols, id: \.self) { s in
                                        Button(s) { symbol = s }
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(symbol == s ? .white : .appTextSecondary)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(symbol == s ? Color.appAccent : Color.appCard)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(symbol == s ? Color.appAccent : Color.appBorder))
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Стратегия")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.appTextSecondary)
                            HStack(spacing: 8) {
                                ForEach(strategies, id: \.self) { s in
                                    Button(strategyLabel(s)) {
                                        withAnimation(.spring(response: 0.3)) { strategy = s }
                                    }
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(strategy == s ? .white : .appTextSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(strategy == s ? Color.appAccent : Color.appCard)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(strategy == s ? Color.appAccent : Color.appBorder))
                                }
                            }
                        }

                        inputField("Начальный капитал ($)", text: $capital, icon: "dollarsign.circle")

                        Button {
                            Task {
                                await vm.createBot(name: name, symbol: symbol.uppercased(),
                                                   strategy: strategy, capital: Double(capital) ?? 10000)
                                dismiss()
                            }
                        } label: {
                            Text("Создать бота")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(name.isEmpty ? Color.appTextDim : Color.appAccent)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(name.isEmpty)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Новый бот")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "#0c1020"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(.appTextSecondary)
                }
            }
        }
    }

    private func inputField(_ placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.appTextSecondary)
                .font(.system(size: 14))
            TextField(placeholder, text: text)
                .font(.system(size: 14))
                .foregroundColor(.appTextPrimary)
                .tint(.appAccent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
    }
}
