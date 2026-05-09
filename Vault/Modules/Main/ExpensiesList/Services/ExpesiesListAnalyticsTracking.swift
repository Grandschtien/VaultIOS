import Foundation

protocol ExpesiesListAnalyticsTracking: Sendable {
    func trackScreenOpen()
    func trackScreenSuccess()
    func trackScreenFailure(_ error: Error)
}

final class ExpesiesListAnalyticsTracker: ExpesiesListAnalyticsTracking {
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
        analyticsCoreManager.sendEvent(provider: .all, event: .screenOpen(.expensesList), payload: [:])
    }

    func trackScreenSuccess() {
        analyticsCoreManager.sendEvent(provider: .all, event: .screenSuccess(.expensesList), payload: [:])
    }

    func trackScreenFailure(_ error: Error) {
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .screenFailure(.expensesList),
            payload: failurePayloadResolver.makePayload(for: error)
        )
    }
}
