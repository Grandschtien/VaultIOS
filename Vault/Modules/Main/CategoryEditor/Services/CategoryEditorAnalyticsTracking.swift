import Foundation

protocol CategoryEditorAnalyticsTracking: Sendable {
    func trackScreenOpen()
    func trackPaywallOpen(currentTier: String)
}

final class CategoryEditorAnalyticsTracker: CategoryEditorAnalyticsTracking {
    private let analyticsCoreManager: AnalyticsCoreManaging

    init(analyticsCoreManager: AnalyticsCoreManaging) {
        self.analyticsCoreManager = analyticsCoreManager
    }

    func trackScreenOpen() {
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .screenOpen(.categoryCreate),
            payload: [:]
        )
    }

    func trackPaywallOpen(currentTier: String) {
        var payload: [String: Any] = [
            "source_screen": AnalyticsScreen.categoryCreate.rawValue
        ]

        if !currentTier.isEmpty {
            payload["current_tier"] = currentTier
        }

        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .paywallOpen(source: .categoryCreate),
            payload: payload
        )
    }
}
