import Foundation

protocol AnalyticsModuleAnalyticsTracking: Sendable {
    func trackScreenOpen()
    func trackScreenSuccess()
    func trackScreenFailure(_ error: Error)
}

final class AnalyticsModuleAnalyticsTracker: AnalyticsModuleAnalyticsTracking {
    private let analyticsCoreManager: AnalyticsCoreManaging
    private let failurePayloadResolver: AnalyticsFailurePayloadResolving

    init(
        analyticsCoreManager: AnalyticsCoreManaging,
        failurePayloadResolver: AnalyticsFailurePayloadResolving
    ) {
        self.analyticsCoreManager = analyticsCoreManager
        self.failurePayloadResolver = failurePayloadResolver
    }

    func trackScreenOpen() {
        analyticsCoreManager.sendEvent(provider: .all, event: .screenOpen(.analytics), payload: [:])
    }

    func trackScreenSuccess() {
        analyticsCoreManager.sendEvent(provider: .all, event: .screenSuccess(.analytics), payload: [:])
    }

    func trackScreenFailure(_ error: Error) {
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .screenFailure(.analytics),
            payload: failurePayloadResolver.makePayload(for: error)
        )
    }
}
