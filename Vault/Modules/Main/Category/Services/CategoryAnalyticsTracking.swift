import Foundation

protocol CategoryAnalyticsTracking: Sendable {
    func trackScreenOpen()
    func trackScreenSuccess()
    func trackScreenFailure(_ error: Error)
}

final class CategoryAnalyticsTracker: CategoryAnalyticsTracking {
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
        analyticsCoreManager.sendEvent(provider: .all, event: .screenOpen(.category), payload: [:])
    }

    func trackScreenSuccess() {
        analyticsCoreManager.sendEvent(provider: .all, event: .screenSuccess(.category), payload: [:])
    }

    func trackScreenFailure(_ error: Error) {
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .screenFailure(.category),
            payload: failurePayloadResolver.makePayload(for: error)
        )
    }
}
