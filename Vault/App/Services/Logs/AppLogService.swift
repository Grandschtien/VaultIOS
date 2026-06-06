import Foundation

protocol AppLogServiceProtocol: Sendable {
    var sessionID: String { get }

    func log(entry: AppLogEntry)
    func log(
        category: AppLogCategory,
        name: String,
        source: String,
        payload: [String: Any],
        requestID: String?,
        subscriptionAttemptID: String?
    )
}

extension AppLogServiceProtocol {
    func log(
        category: AppLogCategory,
        name: String,
        source: String,
        payload: [String: Any] = [:],
        requestID: String? = nil,
        subscriptionAttemptID: String? = nil
    ) {
        log(
            category: category,
            name: name,
            source: source,
            payload: payload,
            requestID: requestID,
            subscriptionAttemptID: subscriptionAttemptID
        )
    }
}

final class AppLogService: AppLogServiceProtocol, @unchecked Sendable {
    private let queue: DispatchQueue
    private let sinks: [any AppLogSinkProtocol]

    let sessionID: String

    init(
        sinks: [any AppLogSinkProtocol],
        sessionID: String = UUID().uuidString.lowercased(),
        queue: DispatchQueue = DispatchQueue(label: "Vault.AppLogs.Service")
    ) {
        self.sinks = sinks
        self.sessionID = sessionID
        self.queue = queue
    }

    func log(entry: AppLogEntry) {
        queue.async { [sinks] in
            sinks.forEach { $0.write(entry) }
        }
    }

    func log(
        category: AppLogCategory,
        name: String,
        source: String,
        payload: [String: Any],
        requestID: String?,
        subscriptionAttemptID: String?
    ) {
        log(
            entry: AppLogEntry(
                timestamp_utc: Self.makeTimestamp(),
                session_id: sessionID,
                category: category,
                name: name,
                source: source,
                payload: payload.reduce(into: [:]) { partialResult, element in
                    partialResult[element.key] = AppLogValue(rawValue: element.value)
                },
                request_id: requestID,
                subscription_attempt_id: subscriptionAttemptID
            )
        )
    }
}

private extension AppLogService {
    static func makeTimestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }
}
