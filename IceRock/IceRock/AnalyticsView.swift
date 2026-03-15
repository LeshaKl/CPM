import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var vm: PortfolioViewModel

    let metrics: [(String, String, String, Color)] = [
        ("β",   "Beta портфеля",   "0.87",  Color(hex:"#93c5fd")),
        ("α",   "Alpha",           "+2.4%", Color(hex:"#34d399")),
        ("⚡",  "VaR (95%)",       "−4.2%", Color(hex:"#f87171")),
        ("∞",   "Корреляция",      "0.61",  Color(hex:"#fbbf24")),
        ("↓",   "Макс. дродаун",  "−8.3%", Color(hex:"#f87171")),
        ("~",   "Волатильность",   "12.4%", Color(hex:"#fbbf24")),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        metricsGrid
                        allocationSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Аналитика")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(hex: "#0c1020"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(Array(metrics.enumerated()), id: \.offset) { _, m in
                VStack(alignment: .leading, spacing: 6) {
                    Text(m.0)
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(m.3)
                    Text(m.1)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                    Text(m.2)
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(m.3)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(m.3.opacity(0.25), lineWidth: 1)
                )
            }
        }
    }

    private var allocationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.appAccent)
                    .font(.system(size: 14))
                Text("Аллокация по секторам")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.appTextPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)

            ForEach(vm.allocationBySector(), id: \.sector) { item in
                AllocationBarRow(sector: item.sector,
                                  fraction: item.fraction,
                                  color: item.color,
                                  value: vm.assets.filter { $0.sector == item.sector }
                                         .reduce(0) { $0 + $1.positionValue })
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
    }
}

struct AllocationBarRow: View {
    let sector: String
    let fraction: Double
    let color: Color
    let value: Double

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(sector)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Text(String(format: "%.1f%%", fraction * 100))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
                Text("·")
                    .foregroundColor(.appTextSecondary)
                Text(shortFmt(value) + " ₽")
                    .font(.system(size: 11))
                    .foregroundColor(.appTextSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appBorder)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [color.opacity(0.9), color.opacity(0.5)],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(fraction), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}
