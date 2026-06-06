import Foundation

protocol ExpenseManualEntryAnalyticsTracking: Sendable {
    func trackScreenOpen()
    func trackPageChange(page: Int)
    func trackTapCategory()
    func trackTapPrimaryButton(isFinalStep: Bool)
    func trackTapSkip()
    func trackTapClose()
}

final class ExpenseManualEntryAnalyticsTracker: ExpenseManualEntryAnalyticsTracking {
    private let analyticsCoreManager: AnalyticsCoreManaging

    init(analyticsCoreManager: AnalyticsCoreManaging) {
        self.analyticsCoreManager = analyticsCoreManager
    }

    func trackScreenOpen() {
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .screenOpen(.expenseManualEntry),
            payload: [:]
        )
    }

    func trackPageChange(page: Int) {
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .tap(.manualPageChange),
            payload: ["page": page]
        )
    }

    func trackTapCategory() {
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .tap(.manualTapCategory),
            payload: [:]
        )
    }

    func trackTapPrimaryButton(isFinalStep: Bool) {
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .tap(isFinalStep ? .manualTapPrimaryConfirm : .manualTapPrimaryNext),
            payload: [:]
        )
    }

    func trackTapSkip() {
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .tap(.manualTapSkip),
            payload: [:]
        )
    }

    func trackTapClose() {
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .tap(.manualTapClose),
            payload: [:]
        )
    }
}
