import SwiftUI

struct HomeView: View {
    @EnvironmentObject var vm: PortfolioViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        HeaderCardView()
                        KPIRowView()
                        PieChartCardView()
                        PRICardView()
                        SummaryCardView()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.appAccent)
                            .font(.system(size: 16, weight: .bold))
                        Text("InvestPro")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.appAccent)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        vm.isDark.toggle()
                    } label: {
                        Image(systemName: vm.isDark ? "sun.max.fill" : "moon.fill")
                            .foregroundColor(.appGold)
                    }
                }
            }
            .toolbarBackground(Color(hex: "#0c1020"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

struct HeaderCardView: View {
    @EnvironmentObject var vm: PortfolioViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    LinearGradient(colors: [Color(hex:"#4f6ef7"), Color(hex:"#8b5cf6")],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                    Text("КР")
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(.white)
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Кирилл Рудаков")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.appAccent)
                        Text("Премиум · Верифицирован")
                            .font(.system(size: 11))
                            .foregroundColor(.appAccent)
                    }
                }
                Spacer()
                Button {
                } label: {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.appTextSecondary)
                        .font(.system(size: 18))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider().background(Color.appBorder)

            HStack(spacing: 0) {
                StatMiniView(title: "Доходность", value: "+14.73%", color: .appGreen)
                Divider().background(Color.appBorder).frame(height: 36)
                StatMiniView(title: "Инд. риска", value: "2.34/10", color: .appBlue)
                Divider().background(Color.appBorder).frame(height: 36)
                StatMiniView(title: "Позиций", value: "\(vm.assets.count) акт.", color: .appBlue)
            }
            .padding(.vertical, 10)

            Divider().background(Color.appBorder)

            VStack(spacing: 2) {
                Text("Стоимость портфеля")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.appTextSecondary)
                Text("2 497 381 644 ₽")
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: Color.appAccent.opacity(0.4), radius: 8)
            }
            .padding(.vertical, 12)
        }
        .background(Color(hex: "#0e1526"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
    }
}

struct StatMiniView: View {
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

struct KPIRowView: View {
    let kpis: [(String, String, String, Color)] = [
        ("💹", "Прибыль сегодня", "+287 430 ₽",   .appGreen),
        ("📉", "Макс. просадка",  "−3.8%",         .appRed),
        ("🔄", "Оборот 30д",      "18.4 млрд ₽",  .appBlue),
        ("⭐", "Шарп/Сортино",    "1.42/1.87",     .appGold),
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(Array(kpis.enumerated()), id: \.offset) { _, kpi in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text(kpi.0).font(.system(size: 18))
                        Text(kpi.1)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                    }
                    Text(kpi.2)
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(kpi.3)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder, lineWidth: 1))
            }
        }
    }
}

struct PieChartCardView: View {
    @EnvironmentObject var vm: PortfolioViewModel
    @State private var hoveredIndex: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Состав портфеля")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.appTextPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 14)

            InteractivePieChartView(slices: vm.pieSlices(), hoveredIndex: $hoveredIndex)
                .frame(height: 240)
                .padding(.horizontal, 8)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(Array(vm.pieSlices().enumerated()), id: \.offset) { i, slice in
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(slice.color)
                            .frame(width: 10, height: 10)
                        Text(slice.asset.ticker)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(i == hoveredIndex ? .appTextPrimary : .appTextSecondary)
                        Spacer()
                        Text(String(format: "%.1f%%", slice.fraction * 100))
                            .font(.system(size: 10))
                            .foregroundColor(.appTextSecondary)
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
        }
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
    }
}

struct InteractivePieChartView: View {
    let slices: [(asset: Asset, fraction: Double, color: Color)]
    @Binding var hoveredIndex: Int?
    @State private var dragLocation: CGPoint = .zero

    var body: some View {
        GeometryReader { geo in
            let size   = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
            let radius = size / 2 - 10
            let inner  = radius * 0.52

            ZStack {
                ForEach(Array(slices.enumerated()), id: \.offset) { i, slice in
                    let (startAngle, endAngle) = angleRange(for: i)
                    let isHovered = hoveredIndex == i
                    let midAngle = (startAngle + endAngle) / 2
                    let offset = isHovered ? 10.0 : 0.0
                    let ox = offset * cos(midAngle * .pi / 180)
                    let oy = offset * sin(midAngle * .pi / 180)

                    PieSliceShape(startAngle: startAngle, endAngle: endAngle)
                        .fill(slice.color.opacity(isHovered ? 1.0 : 0.85))
                        .overlay(
                            PieSliceShape(startAngle: startAngle, endAngle: endAngle)
                                .stroke(isHovered ? Color.white.opacity(0.6) : Color.clear, lineWidth: 2)
                        )
                        .offset(x: ox, y: oy)
                        .frame(width: radius*2, height: radius*2)
                        .position(center)
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
                }

                Circle()
                    .fill(
                        RadialGradient(colors: [Color(hex:"#161b2f"), Color(hex:"#0e1526")],
                                       center: .center, startRadius: 0, endRadius: inner)
                    )
                    .frame(width: inner*2, height: inner*2)
                    .position(center)

                VStack(spacing: 3) {
                    if let idx = hoveredIndex, idx < slices.count {
                        let s = slices[idx]
                        Text(s.asset.ticker)
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(s.color)
                        Text(s.asset.sector)
                            .font(.system(size: 9))
                            .foregroundColor(.appTextSecondary)
                        Text(String(format: "%.1f%%", s.fraction*100))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.appTextPrimary)
                        Text((s.asset.isUp ? "▲ +" : "▼ ") +
                             String(format: "%.2f%%", abs(s.asset.changePercent)))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(s.asset.isUp ? .appGreen : .appRed)
                    } else {
                        Text("Портфель")
                            .font(.system(size: 10))
                            .foregroundColor(.appTextSecondary)
                        Text("2.50 млрд")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.appTextPrimary)
                    }
                }
                .position(center)
                .animation(.easeInOut(duration: 0.15), value: hoveredIndex)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        let pt  = val.location
                        let dx  = pt.x - center.x
                        let dy  = pt.y - center.y
                        let dist = sqrt(dx*dx + dy*dy)
                        guard dist >= inner && dist <= radius + 14 else {
                            hoveredIndex = nil; return
                        }
                        var angle = atan2(dy, dx) * 180 / .pi + 90
                        if angle < 0 { angle += 360 }
                        var cumulative = 0.0
                        for (i, s) in slices.enumerated() {
                            let span = s.fraction * 360
                            if angle >= cumulative && angle < cumulative + span {
                                hoveredIndex = i; return
                            }
                            cumulative += span
                        }
                        hoveredIndex = nil
                    }
                    .onEnded { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            hoveredIndex = nil
                        }
                    }
            )
        }
    }

    private func angleRange(for index: Int) -> (Double, Double) {
        var start = -90.0
        for i in 0..<index { start += slices[i].fraction * 360 }
        return (start, start + slices[index].fraction * 360)
    }
}

struct PieSliceShape: Shape {
    let startAngle: Double
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius,
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(endAngle), clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct PRICardView: View {
    let value: Double = 2.34
    let max: Double   = 10.0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(.appBlue)
                Text("Personal Risk Index")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Text(String(format: "%.2f / %.0f", value, max))
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.appTextPrimary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.appBorder)
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 5)
                        .fill(LinearGradient(
                            colors: [Color(hex:"#34d399"), Color(hex:"#fbbf24"),
                                     Color(hex:"#f97316"), Color(hex:"#ef4444")],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * (value/max), height: 10)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                        .offset(x: geo.size.width * (value/max) - 8)
                }
            }
            .frame(height: 16)

            HStack {
                ForEach(["Мин","Низкий","Средний","Высокий","Экстрем"], id: \.self) { z in
                    Text(z)
                        .font(.system(size: 8))
                        .foregroundColor(.appTextSecondary)
                    if z != "Экстрем" { Spacer() }
                }
            }

            Text("Умеренный уровень риска. Защитные активы (ОФЗ, золото) — 38% портфеля.")
                .font(.system(size: 11))
                .foregroundColor(.appTextSecondary)
        }
        .padding(14)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
    }
}

struct SummaryCardView: View {
    @EnvironmentObject var vm: PortfolioViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Сводка портфеля")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.appTextPrimary)
                .padding(.horizontal, 14)
                .padding(.top, 12)

            ForEach(vm.assets) { asset in
                SummaryAssetRow(asset: asset)
                if asset.id != vm.assets.last?.id {
                    Divider().background(Color.appBorder).padding(.horizontal, 14)
                }
            }
            .padding(.bottom, 10)
        }
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
    }
}

struct SummaryAssetRow: View {
    let asset: Asset

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                sectorColor(asset.sector).opacity(0.2)
                Text(String(asset.ticker.prefix(2)))
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(sectorColor(asset.sector))
            }
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(asset.ticker)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Text(asset.name)
                    .font(.system(size: 10))
                    .foregroundColor(.appTextSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f ₽", asset.currentPrice))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(asset.isUp ? .appGreen : .appRed)
                Text((asset.isUp ? "▲ +" : "▼ ") +
                     String(format: "%.2f%%", abs(asset.changePercent)))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(asset.isUp ? .appGreen : .appRed)
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text(fmtRub(asset.profit))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(asset.profit >= 0 ? .appGreen : .appRed)
                Text("\(asset.tickCount) шт.")
                    .font(.system(size: 10))
                    .foregroundColor(.appTextSecondary)
            }
            .frame(width: 90, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}
