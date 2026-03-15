import SwiftUI

struct MoreView: View {
    @EnvironmentObject var vm: PortfolioViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                List {
                    NavigationLink {
                        DividendsView()
                    } label: {
                        Label("Дивидендный календарь", systemImage: "calendar.badge.plus")
                            .foregroundColor(.appTextPrimary)
                    }

                    NavigationLink {
                        ScreenerView()
                    } label: {
                        Label("Скринер активов", systemImage: "magnifyingglass.circle.fill")
                            .foregroundColor(.appTextPrimary)
                    }

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Настройки", systemImage: "gearshape.fill")
                            .foregroundColor(.appTextPrimary)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.appBackground)
            }
            .navigationTitle("Ещё")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(hex: "#0c1020"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

struct DividendsView: View {
    @EnvironmentObject var vm: PortfolioViewModel

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(vm.dividends) { div in
                        DividendRow(div: div)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Дивиденды")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color(hex: "#0c1020"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct DividendRow: View {
    let div: DividendEvent

    var body: some View {
        HStack(spacing: 12) {
            Text(div.ticker)
                .font(.system(size: 12, weight: .black))
                .foregroundColor(.white)
                .frame(width: 66, height: 34)
                .background(Color.appAccent)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(div.company)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(.appTextSecondary)
                    Text(div.date)
                        .font(.system(size: 11))
                        .foregroundColor(.appTextSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(div.amount)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.appGreen)
                Text(div.yield)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.appGold)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1))
    }
}

struct ScreenerView: View {
    @EnvironmentObject var vm: PortfolioViewModel
    @State private var activeFilters: Set<String> = []

    let filters = ["P/E < 15", "Div > 5%", "ROE > 20%", "Beta < 1.0"]

    var filteredRows: [ScreenerRow] {
        vm.screener.filter { row in
            if activeFilters.contains("P/E < 15")  && row.pe >= 15       { return false }
            if activeFilters.contains("Div > 5%")  && row.divYield <= 5  { return false }
            if activeFilters.contains("ROE > 20%") && row.roe <= 20      { return false }
            if activeFilters.contains("Beta < 1.0") && row.beta >= 1.0    { return false }
            return true
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                filterChips
                Divider().background(Color.appBorder)
                headerRow
                Divider().background(Color.appBorder)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 6) {
                        ForEach(filteredRows) { row in
                            ScreenerRowView(row: row)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
        }
        .navigationTitle("Скринер")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color(hex: "#0c1020"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { f in
                    Button(f) {
                        withAnimation {
                            if activeFilters.contains(f) { activeFilters.remove(f) }
                            else { activeFilters.insert(f) }
                        }
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(activeFilters.contains(f) ? .appAccent : .appTextSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(activeFilters.contains(f) ? Color.appAccent.opacity(0.15) : Color.appCard)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(activeFilters.contains(f) ? Color.appAccent : Color.appBorder, lineWidth: 1))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var headerRow: some View {
        HStack {
            Text("Тикер").font(.system(size: 10, weight: .bold)).foregroundColor(.appTextSecondary).frame(width: 54, alignment: .leading)
            Text("P/E").font(.system(size: 10, weight: .bold)).foregroundColor(.appTextSecondary).frame(maxWidth: .infinity)
            Text("Div%").font(.system(size: 10, weight: .bold)).foregroundColor(.appTextSecondary).frame(maxWidth: .infinity)
            Text("ROE").font(.system(size: 10, weight: .bold)).foregroundColor(.appTextSecondary).frame(maxWidth: .infinity)
            Text("Beta").font(.system(size: 10, weight: .bold)).foregroundColor(.appTextSecondary).frame(maxWidth: .infinity)
            Text("Кап.").font(.system(size: 10, weight: .bold)).foregroundColor(.appTextSecondary).frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.appBackground)
    }
}

struct ScreenerRowView: View {
    let row: ScreenerRow

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.ticker)
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.appBlue)
                Text(row.name)
                    .font(.system(size: 9))
                    .foregroundColor(.appTextSecondary)
            }
            .frame(width: 70, alignment: .leading)

            Group {
                Text(String(format: "%.1f", row.pe))
                    .foregroundColor(row.pe < 15 ? .appGreen : .appTextPrimary)
                Text(String(format: "%.1f%%", row.divYield))
                    .foregroundColor(row.divYield > 5 ? .appGreen : .appTextPrimary)
                Text(String(format: "%.1f%%", row.roe))
                    .foregroundColor(row.roe > 20 ? .appGreen : .appTextPrimary)
                Text(String(format: "%.2f", row.beta))
                    .foregroundColor(row.beta < 1.0 ? .appGreen : .appGold)
                Text(String(format: "%.0f", row.cap))
                    .foregroundColor(.appTextSecondary)
            }
            .font(.system(size: 12, weight: .semibold))
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder, lineWidth: 1))
    }
}

struct SettingsView: View {
    @EnvironmentObject var vm: PortfolioViewModel

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            List {
                Section("Аккаунт") {
                    settingsRow("person.fill", "Кирилл Рудаков", "Премиум")
                    settingsRow("checkmark.shield.fill", "Верификация", "Пройдена")
                }
                Section("Интерфейс") {
                    HStack {
                        Label("Тёмная тема", systemImage: "moon.fill")
                            .foregroundColor(.appTextPrimary)
                        Spacer()
                        Toggle("", isOn: $vm.isDark)
                            .tint(.appAccent)
                    }
                    settingsRow("bell.fill", "Уведомления", "Включены")
                }
                Section("О приложении") {
                    settingsRow("info.circle.fill", "Версия", "1.0.0")
                    settingsRow("chart.line.uptrend.xyaxis", "InvestPro", "iOS Edition")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
        }
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color(hex: "#0c1020"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func settingsRow(_ icon: String, _ title: String, _ sub: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundColor(.appTextPrimary)
            Spacer()
            Text(sub)
                .font(.system(size: 12))
                .foregroundColor(.appTextSecondary)
        }
    }
}
