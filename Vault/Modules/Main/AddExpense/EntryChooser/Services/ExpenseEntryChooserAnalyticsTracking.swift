import Foundation

protocol ExpenseEntryChooserAnalyticsTracking: Sendable {
    func trackScreenOpen()
    func trackPaywallOpen(currentTier: String)
}

final class ExpenseEntryChooserAnalyticsTracker: ExpenseEntryChooserAnalyticsTracking {
    private let analyticsCoreManager: AnalyticsCoreManaging

    init(analyticsCoreManager: AnalyticsCoreManaging) {
        self.analyticsCoreManager = analyticsCoreManager
    }

    func trackScreenOpen() {
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .screenOpen(.expenseEntryChooser),
            payload: [:]
        )
    }

    func trackPaywallOpen(currentTier: String) {
        var payload: [String: Any] = [
            "source_screen": AnalyticsScreen.expenseEntryChooser.rawValue
        ]

        if !currentTier.isEmpty {
            payload["current_tier"] = currentTier
        }

        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .paywallOpen(source: .expenseEntryChooser),
            payload: payload
        )
    }
}
