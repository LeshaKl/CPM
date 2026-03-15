import SwiftUI

struct EquityChartView: View {
    let values: [Double]
    let labels: [String]

    @State private var hoverIndex: Int?
    @State private var trimEnd: CGFloat = 0

    private var isPositive: Bool {
        guard let first = values.first, let last = values.last else { return true }
        return last >= first
    }
    private var accentColor: Color { isPositive ? .appGreen : .appRed }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let padL: CGFloat = 50
            let padR: CGFloat = 8
            let padT: CGFloat = 8
            let padB: CGFloat = 24
            let chartW = w - padL - padR
            let chartH = h - padT - padB

            guard values.count > 1 else { return AnyView(EmptyView()) }
            let minV = values.min()!
            let maxV = values.max()!
            let range = maxV - minV > 0 ? maxV - minV : 1

            func px(_ i: Int) -> CGFloat { padL + chartW * CGFloat(i) / CGFloat(values.count - 1) }
            func py(_ v: Double) -> CGFloat { padT + chartH - chartH * CGFloat((v - minV) / range) }

            let points = values.enumerated().map { CGPoint(x: px($0.offset), y: py($0.element)) }

            return AnyView(
                ZStack(alignment: .topLeading) {
                    ForEach(0..<5, id: \.self) { i in
                        let price = minV + range * Double(i) / 4.0
                        let y = py(price)
                        Path { p in
                            p.move(to: CGPoint(x: padL, y: y))
                            p.addLine(to: CGPoint(x: w - padR, y: y))
                        }
                        .stroke(Color.appBorder.opacity(0.5), style: StrokeStyle(lineWidth: 0.5, dash: [4]))

                        Text(String(format: "$%.0f", price))
                            .font(.system(size: 7))
                            .foregroundColor(.appTextDim)
                            .position(x: padL / 2, y: y)
                    }

                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: padT + chartH))
                        path.addLine(to: points[0])
                        for p in points.dropFirst() { path.addLine(to: p) }
                        path.addLine(to: CGPoint(x: points.last!.x, y: padT + chartH))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(colors: [accentColor.opacity(0.2), accentColor.opacity(0.0)],
                                       startPoint: .top, endPoint: .bottom)
                    )

                    Path { path in
                        path.move(to: points[0])
                        for p in points.dropFirst() { path.addLine(to: p) }
                    }
                    .trim(from: 0, to: trimEnd)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    if let idx = hoverIndex, idx < values.count {
                        let cx = px(idx)
                        let cy = py(values[idx])

                        Path { p in
                            p.move(to: CGPoint(x: cx, y: padT))
                            p.addLine(to: CGPoint(x: cx, y: padT + chartH))
                        }
                        .stroke(accentColor.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3]))

                        Circle()
                            .fill(accentColor)
                            .frame(width: 8, height: 8)
                            .position(x: cx, y: cy)

                        Text(String(format: "$%.2f", values[idx]))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(accentColor.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .position(x: cx, y: cy - 18)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            let x = val.location.x - padL
                            let idx = Int(x / chartW * CGFloat(values.count - 1))
                            hoverIndex = max(0, min(values.count - 1, idx))
                        }
                        .onEnded { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { hoverIndex = nil }
                        }
                )
                .onAppear {
                    withAnimation(.easeOut(duration: 1.2)) { trimEnd = 1.0 }
                }
            )
        }
    }
}
