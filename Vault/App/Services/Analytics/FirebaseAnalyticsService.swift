import FirebaseAnalytics
import FirebaseCore

final class FirebaseAnalyticsService: AnalyticsServiceProtocol, @unchecked Sendable {
    private struct FirebaseEvent {
        let name: String
        let parameters: [String: Any]?
    }

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
        let firebaseEvent = makeFirebaseEvent(for: event, payload: payload)
        await logEventHandler(firebaseEvent.name, firebaseEvent.parameters)
    }
}

private extension FirebaseAnalyticsService {
    private func makeFirebaseEvent(for event: AnalyticsEvent, payload: AnalyticsPayload) -> FirebaseEvent {
        var parameters = payload.foundationValues ?? [:]

        switch event {
        case .subscriptionPurchaseSuccess:
            if let planID = parameters["plan_id"] {
                parameters[AnalyticsParameterItemID] = planID
            }
            if let planTitle = parameters["plan_title"] {
                parameters[AnalyticsParameterItemName] = planTitle
            }

            return FirebaseEvent(
                name: AnalyticsEventPurchase,
                parameters: parameters.isEmpty ? nil : parameters
            )

        case .screenOpen(.main):
            parameters[AnalyticsParameterScreenName] = AnalyticsScreen.main.rawValue
            parameters[AnalyticsParameterScreenClass] = "MainViewController"

            return FirebaseEvent(
                name: AnalyticsEventScreenView,
                parameters: parameters
            )

        default:
            return FirebaseEvent(
                name: event.name,
                parameters: parameters.isEmpty ? nil : parameters
            )
        }
    }
}
