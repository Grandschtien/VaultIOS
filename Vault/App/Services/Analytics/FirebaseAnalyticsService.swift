import FirebaseAnalytics

final class FirebaseAnalyticsService: AnalyticsServiceProtocol, @unchecked Sendable {
    private struct FirebaseEvent {
        let name: String
        let parameters: [String: Any]?
    }

    private let client: FirebaseAnalyticsClientProtocol
    let provider: AnalyticsProvider = .firebase

    init(client: FirebaseAnalyticsClientProtocol = FirebaseAnalyticsClient()) {
        self.client = client
    }

    func send(event: AnalyticsEvent, payload: AnalyticsPayload) async {
        await client.configureIfNeeded()
        let firebaseEvent = makeFirebaseEvent(for: event, payload: payload)
        await client.logEvent(firebaseEvent.name, parameters: firebaseEvent.parameters)
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
                name: makeFirebaseEventName(from: event.name),
                parameters: parameters.isEmpty ? nil : parameters
            )
        }
    }

    // Firebase accepts only letters, numbers and underscores in event names.
    private func makeFirebaseEventName(from name: String) -> String {
        name.replacingOccurrences(of: ".", with: "_")
    }
}
