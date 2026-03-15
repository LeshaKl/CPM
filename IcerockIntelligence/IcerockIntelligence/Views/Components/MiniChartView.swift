import SwiftUI

struct MiniChartView: View {
    let values: [Double]
    let isPositive: Bool

    @State private var trimEnd: CGFloat = 0

    private var color: Color { isPositive ? .appGreen : .appRed }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            guard values.count > 1 else { return AnyView(EmptyView()) }

            let minV = values.min()!
            let maxV = values.max()!
            let range = maxV - minV > 0 ? maxV - minV : 1

            let points: [CGPoint] = values.enumerated().map { i, v in
                CGPoint(
                    x: w * CGFloat(i) / CGFloat(values.count - 1),
                    y: h - h * CGFloat((v - minV) / range)
                )
            }

            return AnyView(
                ZStack {
                    Path { path in
                        path.move(to: points[0])
                        for p in points.dropFirst() { path.addLine(to: p) }
                    }
                    .trim(from: 0, to: trimEnd)
                    .stroke(
                        LinearGradient(colors: [color.opacity(0.6), color], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                    )

                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: h))
                        path.addLine(to: points[0])
                        for p in points.dropFirst() { path.addLine(to: p) }
                        path.addLine(to: CGPoint(x: points.last!.x, y: h))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(colors: [color.opacity(0.15), color.opacity(0.0)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .opacity(Double(trimEnd))
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8)) { trimEnd = 1.0 }
                }
            )
        }
    }
}
