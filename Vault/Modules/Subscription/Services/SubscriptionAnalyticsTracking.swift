import Foundation

protocol SubscriptionAnalyticsTracking: Sendable {
    func trackScreenOpen()
    func trackSubscriptionSuccess(plans: [SubscriptionFetchData.SubscriptionStorePlan], currentTier: String)
    func trackSubscriptionFailure(_ error: Error)
    func trackPurchaseStart(planID: String, planTitle: String, currentTier: String)
    func trackPurchaseSuccess(planID: String, planTitle: String, currentTier: String)
    func trackPurchaseFailure(planID: String, planTitle: String, currentTier: String, error: Error)
}

final class SubscriptionAnalyticsTracker: SubscriptionAnalyticsTracking {
    private let analyticsCoreManager: AnalyticsCoreManaging
    private let failurePayloadResolver: AnalyticsFailurePayloadResolving

    init(
        analyticsCoreManager: AnalyticsCoreManaging,
        failurePayloadResolver: AnalyticsFailurePayloadResolving
    ) {
        self.analyticsCoreManager = analyticsCoreManager
        self.failurePayloadResolver = failurePayloadResolver
    }

    func trackScreenOpen() { track(.screenOpen(.subscription)) }

    func trackSubscriptionSuccess(plans: [SubscriptionFetchData.SubscriptionStorePlan], currentTier: String) {
        track(
            .screenSuccess(.subscription),
            payload: makePlanPayload(plans: plans, currentTier: currentTier)
        )
    }

    func trackSubscriptionFailure(_ error: Error) {
        trackFailure(.screenFailure(.subscription), error: error)
    }

    func trackPurchaseStart(planID: String, planTitle: String, currentTier: String) {
        track(
            .subscriptionPurchaseStart,
            payload: makePurchasePayload(planID: planID, planTitle: planTitle, currentTier: currentTier)
        )
    }

    func trackPurchaseSuccess(planID: String, planTitle: String, currentTier: String) {
        track(
            .subscriptionPurchaseSuccess,
            payload: makePurchasePayload(planID: planID, planTitle: planTitle, currentTier: currentTier)
        )
    }

    func trackPurchaseFailure(planID: String, planTitle: String, currentTier: String, error: Error) {
        trackFailure(
            .subscriptionPurchaseFailure,
            error: error,
            payload: makePurchasePayload(planID: planID, planTitle: planTitle, currentTier: currentTier)
        )
    }
}

private extension SubscriptionAnalyticsTracker {
    func track(_ event: AnalyticsEvent, payload: [String: Any] = [:]) {
        analyticsCoreManager.sendEvent(provider: .all, event: event, payload: payload)
    }

    func trackFailure(_ event: AnalyticsEvent, error: Error, payload: [String: Any] = [:]) {
        track(event, payload: mergedPayload(failurePayloadResolver.makePayload(for: error), payload))
    }

    func makePlanPayload(
        plans: [SubscriptionFetchData.SubscriptionStorePlan],
        currentTier: String
    ) -> [String: Any] {
        var payload: [String: Any] = [
            "plan_count": plans.count,
            "plan_ids_csv": plans.map(\.id).joined(separator: ",")
        ]
        if !currentTier.isEmpty {
            payload["current_tier"] = currentTier
        }

        return payload
    }

    func makePurchasePayload(
        planID: String,
        planTitle: String,
        currentTier: String
    ) -> [String: Any] {
        var payload: [String: Any] = [
            "plan_id": planID,
            "plan_title": planTitle
        ]
        if !currentTier.isEmpty {
            payload["current_tier"] = currentTier
        }

        return payload
    }

    func mergedPayload(_ payloads: [String: Any]...) -> [String: Any] {
        payloads.reduce(into: [:]) { result, payload in
            result.merge(payload) { _, new in new }
        }
    }
}
