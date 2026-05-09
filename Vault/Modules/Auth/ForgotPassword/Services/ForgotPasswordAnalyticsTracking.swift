import Foundation

protocol ForgotPasswordAnalyticsTracking: Sendable {
    func trackScreenOpen()
    func trackForgotPasswordSuccess()
    func trackForgotPasswordFailure(_ error: Error)
}

final class ForgotPasswordAnalyticsTracker: ForgotPasswordAnalyticsTracking {
    private let analyticsCoreManager: AnalyticsCoreManaging
    private let failurePayloadResolver: AnalyticsFailurePayloadResolving

    init(
        analyticsCoreManager: AnalyticsCoreManaging,
        failurePayloadResolver: AnalyticsFailurePayloadResolving
    ) {
        self.analyticsCoreManager = analyticsCoreManager
        self.failurePayloadResolver = failurePayloadResolver
    }

    func trackScreenOpen() { track(.screenOpen(.forgotPassword)) }
    func trackForgotPasswordSuccess() { track(.screenSuccess(.forgotPassword)) }
    func trackForgotPasswordFailure(_ error: Error) {
        trackFailure(.screenFailure(.forgotPassword), error: error)
    }
}

private extension ForgotPasswordAnalyticsTracker {
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
