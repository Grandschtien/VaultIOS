import FirebaseAnalytics
import FirebaseCore

final class FirebaseAnalyticsService: AnalyticsServiceProtocol, @unchecked Sendable {
    private let configureIfNeededHandler: @Sendable () async -> Void
    private let logEventHandler: @Sendable (String, [String: Any]?) async -> Void
    let provider: AnalyticsProvider = .firebase

    init(
        configureIfNeededHandler: @escaping @Sendable () async -> Void = {
            await MainActor.run {
                if FirebaseApp.app() == nil {
                    FirebaseApp.configure()
                }
            }
        },
        logEventHandler: @escaping @Sendable (String, [String: Any]?) async -> Void = { name, parameters in
            await MainActor.run {
                Analytics.logEvent(name, parameters: parameters)
            }
        }
    ) {
        self.configureIfNeededHandler = configureIfNeededHandler
        self.logEventHandler = logEventHandler
    }

    func send(event: AnalyticsEvent, payload: AnalyticsPayload) async {
        await configureIfNeededHandler()
        await logEventHandler(event.name, payload.foundationValues)
    }
}
