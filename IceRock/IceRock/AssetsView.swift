import SwiftUI

struct AssetsView: View {
    @EnvironmentObject var vm: PortfolioViewModel
    @State private var searchText = ""
    @State private var selectedSector = "Все"
    @State private var selectedAsset: Asset? = nil

    let sectors = ["Все","Финансы","Энергетика","Нефть/газ","Технологии","Металлы","Сырьё","Валюта","Облигации","Ритейл"]

    var filtered: [Asset] {
        vm.assets.filter { a in
            let sectorOK = selectedSector == "Все" || a.sector == selectedSector
            let searchOK = searchText.isEmpty ||
                a.ticker.localizedCaseInsensitiveContains(searchText) ||
                a.name.localizedCaseInsensitiveContains(searchText)
            return sectorOK && searchOK
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    searchBar
                    sectorChips
                    Divider().background(Color.appBorder)
                    assetList
                    totalFooter
                }
            }
            .navigationTitle("Активы")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(hex: "#0c1020"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(for: Asset.self) { asset in
                AssetDetailView(asset: asset)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.appTextSecondary)
                .font(.system(size: 14))
            TextField("Поиск актива...", text: $searchText)
                .font(.system(size: 14))
                .foregroundColor(.appTextPrimary)
                .tint(.appAccent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var sectorChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(sectors, id: \.self) { s in
                    Button(s) {
                        withAnimation(.spring(response: 0.3)) { selectedSector = s }
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(selectedSector == s ? .white : .appTextSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedSector == s ? Color.appAccent : Color.appCard)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(selectedSector == s ? Color.appAccent : Color.appBorder, lineWidth: 1))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }

    private var assetList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 6) {
                ForEach(filtered) { asset in
                    NavigationLink(value: asset) {
                        AssetRowCard(asset: asset)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)
        }
    }

    private var totalFooter: some View {
        let total = vm.assets.reduce(0.0) { $0 + $1.profit }
        return HStack {
            Text("Итого P/L:")
                .font(.system(size: 13))
                .foregroundColor(.appTextSecondary)
            Spacer()
            Text(fmtRub(total))
                .font(.system(size: 14, weight: .black))
                .foregroundColor(total >= 0 ? .appGreen : .appRed)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(hex: "#0c1020"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.appBorder), alignment: .top)
    }
}

struct AssetRowCard: View {
    let asset: Asset

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                sectorColor(asset.sector)
                Text(String(asset.ticker.prefix(2)))
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.white)
            }
            .frame(width: 48, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(asset.ticker)
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.appTextPrimary)
                    Text(asset.sector)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.appBorder)
                        .clipShape(Capsule())
                }
                Text(asset.name)
                    .font(.system(size: 11))
                    .foregroundColor(.appTextSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "%.2f ₽", asset.currentPrice))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(asset.isUp ? .appGreen : .appRed)
                HStack(spacing: 3) {
                    Image(systemName: asset.isUp ? "triangle.fill" : "triangle.fill")
                        .font(.system(size: 7))
                        .foregroundColor(asset.isUp ? .appGreen : .appRed)
                        .rotationEffect(asset.isUp ? .zero : .degrees(180))
                    Text(String(format: "%.2f%%", abs(asset.changePercent)))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(asset.isUp ? .appGreen : .appRed)
                }
            }

            VStack(alignment: .trailing, spacing: 3) {
                Text(fmtRub(asset.profit))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(asset.profit >= 0 ? .appGreen : .appRed)
                Text("\(asset.tickCount) шт.")
                    .font(.system(size: 10))
                    .foregroundColor(.appTextSecondary)
            }
            .frame(width: 88, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1))
    }
}

struct AssetDetailView: View {
    let asset: Asset
    @State private var hoverCandleIndex: Int? = nil

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    detailHeader
                    kpiStrip
                    candleSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(asset.ticker)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: "#0c1020"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var detailHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                sectorColor(asset.sector)
                Text(String(asset.ticker.prefix(2)))
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.white)
            }
            .frame(width: 54, height: 88)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                Text(asset.name)
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.appTextPrimary)
                Text(asset.sector + " · " + asset.ticker)
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f ₽", asset.currentPrice))
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(asset.isUp ? .appGreen : .appRed)
                HStack(spacing: 3) {
                    Image(systemName: asset.isUp ? "triangle.fill" : "triangle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(asset.isUp ? .appGreen : .appRed)
                        .rotationEffect(asset.isUp ? .zero : .degrees(180))
                    Text(String(format: "%.2f%%", abs(asset.changePercent)))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(asset.isUp ? .appGreen : .appRed)
                }
            }
        }
        .padding(16)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
    }

    private var kpiStrip: some View {
        let items: [(String, String, Color)] = [
            ("Цена",     String(format: "%.2f ₽", asset.currentPrice), asset.isUp ? .appGreen : .appRed),
            ("Кол-во",   "\(asset.tickCount) шт.",  .appTextPrimary),
            ("Ср.цена",  String(format: "%.2f ₽", asset.avgPrice),    .appTextPrimary),
            ("Позиция",  shortFmt(asset.positionValue) + " ₽",        .appBlue),
            ("P/L",      fmtRub(asset.profit),                         asset.profit >= 0 ? .appGreen : .appRed),
            ("PRI",      String(format: "%.1f/10", asset.personalRisk),.appGold),
        ]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                         spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                VStack(spacing: 4) {
                    Text(item.0)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                        .textCase(.uppercase)
                    Text(item.1)
                        .font(.system(size: 12, weight: .black))
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

    private var candleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.appAccent)
                Text("График · последние 100 дней")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.appTextPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            CandleChartView(candles: Array(asset.candles.suffix(100)))
                .frame(height: 280)
                .padding(.horizontal, 8)
                .padding(.bottom, 12)
        }
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
    }
}

struct CandleChartView: View {
    let candles: [CandleData]
    @State private var hoverIndex: Int? = nil
    @GestureState private var dragX: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let padL: CGFloat = 52
            let padR: CGFloat = 8
            let padT: CGFloat = 8
            let padB: CGFloat = 28
            let chartW = w - padL - padR
            let chartH = h - padT - padB
            let n = candles.count
            guard n > 0 else { return AnyView(EmptyView()) }

            let minP = candles.map(\.low).min()!
            let maxP = candles.map(\.high).max()!
            let range = maxP - minP > 0 ? maxP - minP : 1

            func py(_ price: Double) -> CGFloat {
                padT + chartH - CGFloat((price - minP) / range) * chartH
            }

            let candleW = chartW / CGFloat(n)
            let bodyW = max(2, candleW * 0.65)

            return AnyView(
                ZStack(alignment: .topLeading) {
                    // grid
                    ForEach(0..<5) { i in
                        let price = minP + range * Double(i) / 4.0
                        let y = py(price)
                        Path { p in
                            p.move(to: CGPoint(x: padL, y: y))
                            p.addLine(to: CGPoint(x: w - padR, y: y))
                        }
                        .stroke(Color.appBorder.opacity(0.6), style: StrokeStyle(lineWidth: 0.5, dash: [4]))

                        Text(String(format: "%.0f", price))
                            .font(.system(size: 7))
                            .foregroundColor(.appTextDim)
                            .frame(width: 46, alignment: .trailing)
                            .position(x: padL/2 + 8, y: y)
                    }

                    // candles
                    ForEach(Array(candles.enumerated()), id: \.offset) { i, c in
                        let cx = padL + (CGFloat(i) + 0.5) * candleW
                        let isHov = hoverIndex == i
                        let openY  = py(c.open)
                        let closeY = py(c.close)
                        let highY  = py(c.high)
                        let lowY   = py(c.low)
                        let bodyTop = min(openY, closeY)
                        let bodyH   = max(2, abs(closeY - openY))
                        let col: Color = c.isBullish ? .appGreen : .appRed

                        // wick
                        Path { p in
                            p.move(to: CGPoint(x: cx, y: highY))
                            p.addLine(to: CGPoint(x: cx, y: lowY))
                        }
                        .stroke(col.opacity(isHov ? 1.0 : 0.7), lineWidth: 1)

                        // body
                        RoundedRectangle(cornerRadius: 2)
                            .fill(col.opacity(isHov ? 1.0 : 0.85))
                            .frame(width: bodyW, height: bodyH)
                            .position(x: cx, y: bodyTop + bodyH/2)
                    }

                    // crosshair
                    if let idx = hoverIndex, idx < candles.count {
                        let cx = padL + (CGFloat(idx) + 0.5) * candleW
                        let c  = candles[idx]
                        let cy = py(c.close)

                        // vertical line
                        Path { p in
                            p.move(to: CGPoint(x: cx, y: padT))
                            p.addLine(to: CGPoint(x: cx, y: padT + chartH))
                        }
                        .stroke(Color.appAccent.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4]))

                        // horizontal line
                        Path { p in
                            p.move(to: CGPoint(x: padL, y: cy))
                            p.addLine(to: CGPoint(x: w - padR, y: cy))
                        }
                        .stroke(Color.appAccent.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4]))

                        // price label on Y axis
                        Text(String(format: "%.1f", c.close))
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.appAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .position(x: padL/2 + 8, y: cy)

                        // tooltip
                        let df = DateFormatter()
                        let _ = { df.dateFormat = "dd.MM.yy" }()
                        let tooltipText = "\(df.string(from: c.date))  O:\(String(format:"%.1f",c.open))  H:\(String(format:"%.1f",c.high))  L:\(String(format:"%.1f",c.low))  C:\(String(format:"%.1f",c.close))"
                        let tx = min(max(cx - 90, padL), w - padR - 180)
                        Text(tooltipText)
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(c.isBullish ? .appGreen : .appRed)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(hex:"#1a2a44").opacity(0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .position(x: tx + 90, y: padT + 12)
                    }

                    // date labels
                    ForEach(stride(from: 0, to: candles.count, by: max(1, candles.count/6)).map{$0}, id: \.self) { i in
                        let cx = padL + (CGFloat(i) + 0.5) * candleW
                        let df = DateFormatter()
                        let _ = { df.dateFormat = "dd.MM" }()
                        Text(df.string(from: candles[i].date))
                            .font(.system(size: 7))
                            .foregroundColor(.appTextSecondary)
                            .position(x: cx, y: h - padB/2)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            let x = val.location.x - padL
                            let idx = Int(x / candleW)
                            hoverIndex = max(0, min(candles.count - 1, idx))
                        }
                        .onEnded { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                hoverIndex = nil
                            }
                        }
                )
            )
        }
    }
}
