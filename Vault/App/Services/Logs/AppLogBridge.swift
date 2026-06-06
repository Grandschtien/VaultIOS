import Foundation

enum AppLogBridge {
    private static let lock = NSLock()
    private static var service: AppLogServiceProtocol?

    static func install(service: AppLogServiceProtocol?) {
        lock.lock()
        defer { lock.unlock() }

        self.service = service
    }

    static func log(
        category: AppLogCategory,
        name: String,
        source: String,
        payload: [String: Any] = [:],
        requestID: String? = nil,
        subscriptionAttemptID: String? = nil
    ) {
        resolvedService()?.log(
            category: category,
            name: name,
            source: source,
            payload: payload,
            requestID: requestID,
            subscriptionAttemptID: subscriptionAttemptID
        )
    }

    static func logTap(source: String, payload: [String: Any] = [:]) {
        log(category: .ui, name: "tap", source: source, payload: payload)
    }
}

private extension AppLogBridge {
    static func resolvedService() -> AppLogServiceProtocol? {
        lock.lock()
        defer { lock.unlock() }

        return service
    }
}
