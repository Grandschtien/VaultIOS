import Foundation

protocol RegistrationAnalyticsTracking: Sendable {
    func trackScreenOpen()
    func trackRegistrationSuccess()
    func trackRegistrationFailure(_ error: Error)
}

final class RegistrationAnalyticsTracker: RegistrationAnalyticsTracking {
    private let analyticsCoreManager: AnalyticsCoreManaging
    private let failurePayloadResolver: AnalyticsFailurePayloadResolving

    init(
        analyticsCoreManager: AnalyticsCoreManaging,
        failurePayloadResolver: AnalyticsFailurePayloadResolving
    ) {
        self.analyticsCoreManager = analyticsCoreManager
        self.failurePayloadResolver = failurePayloadResolver
    }

    func trackScreenOpen() { track(.screenOpen(.registration)) }
    func trackRegistrationSuccess() { track(.screenSuccess(.registration)) }
    func trackRegistrationFailure(_ error: Error) {
        trackFailure(.screenFailure(.registration), error: error)
    }
}

private extension RegistrationAnalyticsTracker {
    func track(_ event: AnalyticsEvent, payload: [String: Any] = [:]) {
        analyticsCoreManager.sendEvent(provider: .all, event: event, payload: payload)
    }

    func trackFailure(_ event: AnalyticsEvent, error: Error, payload: [String: Any] = [:]) {
        track(event, payload: mergedPayload(failurePayloadResolver.makePayload(for: error), payload))
    }

    func mergedPayload(_ payloads: [String: Any]...) -> [String: Any] {
        payloads.reduce(into: [:]) { result, payload in
            result.merge(payload) { _, new in new }
        }
    }
}
