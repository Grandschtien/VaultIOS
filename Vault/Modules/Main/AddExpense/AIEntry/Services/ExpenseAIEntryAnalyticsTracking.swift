import Foundation

protocol ExpenseAIEntryAnalyticsTracking: Sendable {
    func trackScreenOpen()
    func trackScreenSuccess()
    func trackMicrophoneTap()
    func trackConfirmTap(prompt: String)
    func trackProcessSuccess(prompt: String, parsedExpenseCount: Int)
    func trackProcessFailure(prompt: String, error: Error)
    func trackNoExpenseDetected(prompt: String)
}

final class ExpenseAIEntryAnalyticsTracker: ExpenseAIEntryAnalyticsTracking {
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
        analyticsCoreManager.sendEvent(provider: .all, event: .screenOpen(.expenseAIEntry), payload: [:])
    }

    func trackScreenSuccess() {
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .screenSuccess(.expenseAIEntry),
            payload: [:]
        )
    }

    func trackMicrophoneTap() {
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .tap(.aiMicrophoneTap),
            payload: [:]
        )
    }

    func trackConfirmTap(prompt: String) {
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .tap(.aiConfirmTap),
            payload: ["prompt": prompt]
        )
    }

    func trackProcessSuccess(prompt: String, parsedExpenseCount: Int) {
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .aiParseSuccess,
            payload: [
                "prompt": prompt,
                "parsed_expense_count": parsedExpenseCount
            ]
        )
    }

    func trackProcessFailure(prompt: String, error: Error) {
        var payload = failurePayloadResolver.makePayload(for: error)
        payload["prompt"] = prompt

        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .aiParseFailure,
            payload: payload
        )
    }

    func trackNoExpenseDetected(prompt: String) {
        analyticsCoreManager.sendEvent(
            provider: .all,
            event: .aiParseFailure,
            payload: [
                "prompt": prompt,
                "error_description": "no_expense_detected"
            ]
        )
    }
}
