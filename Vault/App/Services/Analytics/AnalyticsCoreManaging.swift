protocol AnalyticsCoreManaging: Sendable {
    func sendEvent(provider: AnalyticsProvider, event: AnalyticsEvent, payload: [String: Any])
}
