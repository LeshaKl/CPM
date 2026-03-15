import SwiftUI

struct LogView: View {
    @ObservedObject var wsManager: WebSocketManager
    let botId: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "terminal.fill")
                    .foregroundColor(.appAccent)
                Text("Live Logs")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Circle()
                    .fill(wsManager.logs.isEmpty ? Color.appTextDim : Color.appGreen)
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            if wsManager.logs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 28))
                        .foregroundColor(.appTextDim)
                    Text("Ожидание логов...")
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(wsManager.logs.filter { $0.botId == botId }) { entry in
                            HStack(alignment: .top, spacing: 6) {
                                Text(formatTime(entry.timestamp))
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(.appTextDim)
                                    .frame(width: 50, alignment: .trailing)
                                Text(entry.message)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.appGreen.opacity(0.9))
                            }
                            .padding(.horizontal, 14)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 200)
            }
        }
        .padding(.bottom, 12)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
        .onAppear { wsManager.connect(botId: botId) }
        .onDisappear { wsManager.disconnect() }
    }

    private func formatTime(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss"
        return df.string(from: date)
    }
}
