import SwiftUI

struct StatusBadge: View {
    let status: BotStatusType
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(status.color)
                .frame(width: 7, height: 7)
                .scaleEffect(status == .active && isPulsing ? 1.4 : 1.0)
                .opacity(status == .active && isPulsing ? 0.5 : 1.0)
                .animation(
                    status == .active
                        ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                        : .default,
                    value: isPulsing
                )

            Text(status.label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.12))
        .clipShape(Capsule())
        .onAppear { isPulsing = true }
    }
}
