import Foundation

protocol CategoriesListAnalyticsTracking: Sendable {
    func trackScreenOpen()
    func trackScreenSuccess()
    func trackScreenFailure(_ error: Error)
}

final class CategoriesListAnalyticsTracker: CategoriesListAnalyticsTracking {
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
        analyticsCoreManager.sendEvent(provider: .all, event: .screenOpen(.categoriesList), payload: [:])
    }

    func trackScreenSuccess() {
        analyticsCoreManager.sendEvent(provider: .all, event: .screenSuccess(.categoriesList), payload: [:])
    }

    func trackScreenFailure(_ error: Error) {
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .screenFailure(.categoriesList),
            payload: failurePayloadResolver.makePayload(for: error)
        )
    }
}
