import Foundation
@testable import Vault

final class AppLogServiceSpy: AppLogServiceProtocol, @unchecked Sendable {
    let sessionID: String

    private let lock = NSLock()
    private var storedEntries: [AppLogEntry] = []

    init(sessionID: String = "session-test") {
        self.sessionID = sessionID
    }

    func log(entry: AppLogEntry) {
        lock.lock()
        storedEntries.append(entry)
        lock.unlock()
    }

    func log(
        category: AppLogCategory,
        name: String,
        source: String,
        payload: [String : Any],
        requestID: String?,
        subscriptionAttemptID: String?
    ) {
        log(
            entry: AppLogEntry(
                timestamp_utc: "2026-06-06T00:00:00.000Z",
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

    func entries() async -> [AppLogEntry] {
        lock.lock()
        let entries = storedEntries
        lock.unlock()
        return entries
    }
}
