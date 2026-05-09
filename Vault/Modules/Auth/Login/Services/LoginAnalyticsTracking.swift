import Foundation

protocol LoginAnalyticsTracking: Sendable {
    func trackScreenOpen()
    func trackLoginSuccess()
    func trackLoginFailure(_ error: Error)
}

final class LoginAnalyticsTracker: LoginAnalyticsTracking {
    private let analyticsCoreManager: AnalyticsCoreManaging
    private let failurePayloadResolver: AnalyticsFailurePayloadResolving

    init(
        analyticsCoreManager: AnalyticsCoreManaging,
        failurePayloadResolver: AnalyticsFailurePayloadResolving
    ) {
        self.analyticsCoreManager = analyticsCoreManager
        self.failurePayloadResolver = failurePayloadResolver
    }

    func trackScreenOpen() { track(.screenOpen(.login)) }
    func trackLoginSuccess() { track(.screenSuccess(.login)) }
    func trackLoginFailure(_ error: Error) {
        trackFailure(.screenFailure(.login), error: error)
    }
}

private extension LoginAnalyticsTracker {
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
