import Foundation

protocol MainAnalyticsTracking: Sendable {
    func trackScreenOpen()
}

final class MainAnalyticsTracker: MainAnalyticsTracking {
    private let analyticsCoreManager: AnalyticsCoreManaging

    init(analyticsCoreManager: AnalyticsCoreManaging) {
        self.analyticsCoreManager = analyticsCoreManager
    }

    func trackScreenOpen() {
        analyticsCoreManager.sendEvent(provider: .all, event: .screenOpen(.main), payload: [:])
    }
}
