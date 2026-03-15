import Foundation
import Combine

@MainActor
final class WebSocketManager: ObservableObject {
    @Published var logs: [LogEntry] = []

    private var task: URLSessionWebSocketTask?
    private var isConnected = false

    func connect(botId: Int, baseURL: String = "ws://127.0.0.1:8000") {
        disconnect()
        guard let url = URL(string: "\(baseURL)/ws/logs/\(botId)") else { return }
        task = URLSession.shared.webSocketTask(with: url)
        task?.resume()
        isConnected = true
        listen()
    }

    func disconnect() {
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        isConnected = false
    }

    private func listen() {
        task?.receive { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let message):
                    if case .string(let text) = message {
                        self?.handleMessage(text)
                    }
                    self?.listen()
                case .failure:
                    self?.isConnected = false
                }
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let botId = json["bot_id"] as? Int,
              let message = json["message"] as? String
        else { return }

        let entry = LogEntry(botId: botId, message: message, timestamp: Date())
        logs.insert(entry, at: 0)
        if logs.count > 200 { logs.removeLast() }
    }
}
