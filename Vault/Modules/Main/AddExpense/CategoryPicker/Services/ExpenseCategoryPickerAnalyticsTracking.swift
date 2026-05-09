import Foundation

protocol ExpenseCategoryPickerAnalyticsTracking: Sendable {
    func trackScreenOpen()
    func trackScreenSuccess()
    func trackScreenFailure(_ error: Error)
}

final class ExpenseCategoryPickerAnalyticsTracker: ExpenseCategoryPickerAnalyticsTracking {
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
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .screenOpen(.expenseCategoryPicker),
            payload: [:]
        )
    }

    func trackScreenSuccess() {
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .screenSuccess(.expenseCategoryPicker),
            payload: [:]
        )
    }

    func trackScreenFailure(_ error: Error) {
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .screenFailure(.expenseCategoryPicker),
            payload: failurePayloadResolver.makePayload(for: error)
        )
    }
}
