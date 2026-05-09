import Foundation

protocol ProfileAnalyticsTracking: Sendable {
    func trackScreenOpen()
    func trackProfileSuccess()
    func trackProfileFailure(_ error: Error)
    func trackCurrencyScreenOpen()
    func trackCurrencySaveSuccess(previousCurrencyCode: String, updatedCurrencyCode: String)
    func trackCurrencySaveFailure(previousCurrencyCode: String, updatedCurrencyCode: String, error: Error)
    func trackLogoutScreenOpen()
    func trackLogoutSuccess()
    func trackLogoutFailure(_ error: Error)
    func trackPaywallOpen(currentTier: String)
}

final class ProfileAnalyticsTracker: ProfileAnalyticsTracking {
    private let analyticsCoreManager: AnalyticsCoreManaging
    private let failurePayloadResolver: AnalyticsFailurePayloadResolving

    init(
        analyticsCoreManager: AnalyticsCoreManaging,
        failurePayloadResolver: AnalyticsFailurePayloadResolving
    ) {
        self.analyticsCoreManager = analyticsCoreManager
        self.failurePayloadResolver = failurePayloadResolver
    }

    func trackScreenOpen() { track(.screenOpen(.profile)) }
    func trackProfileSuccess() { track(.screenSuccess(.profile)) }
    func trackProfileFailure(_ error: Error) {
        trackFailure(.screenFailure(.profile), error: error)
    }

    func trackCurrencyScreenOpen() {
        track(.screenOpen(.profileCurrency))
    }

    func trackCurrencySaveSuccess(previousCurrencyCode: String, updatedCurrencyCode: String) {
        track(
            .screenSuccess(.profileCurrency),
            payload: [
                "previous_currency_code": previousCurrencyCode,
                "updated_currency_code": updatedCurrencyCode
            ]
        )
    }

    func trackCurrencySaveFailure(previousCurrencyCode: String, updatedCurrencyCode: String, error: Error) {
        trackFailure(
            .screenFailure(.profileCurrency),
            error: error,
            payload: [
                "previous_currency_code": previousCurrencyCode,
                "updated_currency_code": updatedCurrencyCode
            ]
        )
    }

    func trackLogoutScreenOpen() { track(.screenOpen(.logout)) }
    func trackLogoutSuccess() { track(.screenSuccess(.logout)) }
    func trackLogoutFailure(_ error: Error) {
        trackFailure(.screenFailure(.logout), error: error)
    }

    func trackPaywallOpen(currentTier: String) {
        var payload: [String: Any] = ["source_screen": AnalyticsScreen.profile.rawValue]
        if !currentTier.isEmpty {
            payload["current_tier"] = currentTier
        }

        track(.paywallOpen(source: .profile), payload: payload)
    }
}

private extension ProfileAnalyticsTracker {
    func track(_ event: AnalyticsEvent, payload: [String: Any] = [:]) {
        analyticsCoreManager.sendEvent(provider: .all, event: event, payload: payload)
    }

    func trackFailure(_ event: AnalyticsEvent, error: Error, payload: [String: Any] = [:]) {
        track(event, payload: mergedPayload(failurePayloadResolver.makePayload(for: error), payload))
    }

    func mergedPayload(_ payloads: [String: Any]...) -> [String: Any] {
        payloads.reduce(into: [:]) { result, payload in
            result.merge(payload) { _, new in new }
        }
    }
}
