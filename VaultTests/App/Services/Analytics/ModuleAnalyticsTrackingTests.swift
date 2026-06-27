import XCTest
@testable import Vylok

final class ModuleAnalyticsTrackingTests: XCTestCase {
    func testAuthAnalyticsServicesSendExpectedEvents() {
        let analyticsCoreManager = AnalyticsCoreManagingSpy()
        let failurePayloadResolver = AnalyticsFailurePayloadResolverSpy()

        LoginAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
        .trackLoginSuccess()
        RegistrationAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
        .trackRegistrationFailure(StubError.any)
        ForgotPasswordAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
        .trackScreenOpen()

        XCTAssertEqual(analyticsCoreManager.calls.map(\.event), [
            .screenSuccess(.login),
            .screenFailure(.registration),
            .screenOpen(.forgotPassword)
        ])
    }

    func testProfileAnalyticsServiceBuildsCurrencyAndPaywallPayload() {
        let analyticsCoreManager = AnalyticsCoreManagingSpy()
        let sut = ProfileAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: AnalyticsFailurePayloadResolverSpy()
        )

        sut.trackCurrencySaveSuccess(previousCurrencyCode: "USD", updatedCurrencyCode: "EUR")
        sut.trackPaywallOpen(currentTier: "PREMIUM")

        XCTAssertEqual(analyticsCoreManager.calls[0].event, .screenSuccess(.profileCurrency))
        XCTAssertEqual(analyticsCoreManager.calls[0].payload["previous_currency_code"] as? String, "USD")
        XCTAssertEqual(analyticsCoreManager.calls[0].payload["updated_currency_code"] as? String, "EUR")
        XCTAssertEqual(analyticsCoreManager.calls[1].event, .paywallOpen(source: .profile))
        XCTAssertEqual(analyticsCoreManager.calls[1].payload["source_screen"] as? String, AnalyticsScreen.profile.rawValue)
        XCTAssertEqual(analyticsCoreManager.calls[1].payload["current_tier"] as? String, "PREMIUM")
    }

    func testSubscriptionAnalyticsServiceBuildsPlanPayload() {
        let analyticsCoreManager = AnalyticsCoreManagingSpy()
        let sut = SubscriptionAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: AnalyticsFailurePayloadResolverSpy()
        )

        sut.trackSubscriptionSuccess(
            plans: [
                .init(id: "plan.a", title: "Plan A", price: "$1"),
                .init(id: "plan.b", title: "Plan B", price: "$2")
            ],
            currentTier: "FREE"
        )
        sut.trackPurchaseFailure(planID: "plan.a", planTitle: "Plan A", currentTier: "FREE", error: StubError.any)

        XCTAssertEqual(analyticsCoreManager.calls[0].event, .screenSuccess(.subscription))
        XCTAssertEqual(analyticsCoreManager.calls[0].payload["plan_count"] as? Int, 2)
        XCTAssertEqual(analyticsCoreManager.calls[0].payload["plan_ids_csv"] as? String, "plan.a,plan.b")
        XCTAssertEqual(analyticsCoreManager.calls[1].event, .subscriptionPurchaseFailure)
        XCTAssertEqual(analyticsCoreManager.calls[1].payload["plan_id"] as? String, "plan.a")
        XCTAssertEqual(analyticsCoreManager.calls[1].payload["plan_title"] as? String, "Plan A")
        XCTAssertEqual(analyticsCoreManager.calls[1].payload["error_description"] as? String, "stub-error")
    }

    func testMainFlowAnalyticsServicesSendExpectedScreenOpenEvents() {
        let analyticsCoreManager = AnalyticsCoreManagingSpy()
        let failurePayloadResolver = AnalyticsFailurePayloadResolverSpy()

        CategoryAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
            .trackScreenOpen()
        ExpenseCategoryPickerAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
            .trackScreenOpen()
        CategoriesListAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
            .trackScreenOpen()
        ExpesiesListAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
            .trackScreenOpen()
        AnalyticsModuleAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
            .trackScreenOpen()

        XCTAssertEqual(analyticsCoreManager.calls.map(\.event), [
            .screenOpen(.category),
            .screenOpen(.expenseCategoryPicker),
            .screenOpen(.categoriesList),
            .screenOpen(.expensesList),
            .screenOpen(.analytics)
        ])
    }

    func testExpenseAIEntryAnalyticsServiceTracksOpenMicrophoneAndConfirmTap() {
        let analyticsCoreManager = AnalyticsCoreManagingSpy()
        let sut = ExpenseAIEntryAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: AnalyticsFailurePayloadResolverSpy()
        )

        sut.trackScreenOpen()
        sut.trackMicrophoneTap()
        sut.trackConfirmTap(prompt: "Coffee 12")

        XCTAssertEqual(analyticsCoreManager.calls[0].event, .screenOpen(.expenseAIEntry))
        XCTAssertEqual(analyticsCoreManager.calls[1].event, .tap(.aiMicrophoneTap))
        XCTAssertEqual(analyticsCoreManager.calls[2].event, .tap(.aiConfirmTap))
        XCTAssertEqual(analyticsCoreManager.calls[2].payload["prompt"] as? String, "Coffee 12")
    }

    func testMainFlowAnalyticsServicesSendSuccessAndFailureEvents() {
        let analyticsCoreManager = AnalyticsCoreManagingSpy()
        let failurePayloadResolver = AnalyticsFailurePayloadResolverSpy()

        CategoryAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
        .trackScreenSuccess()
        CategoriesListAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
        .trackScreenFailure(StubError.any)
        ExpesiesListAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
        .trackScreenSuccess()
        ExpenseCategoryPickerAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
        .trackScreenFailure(StubError.any)
        AnalyticsModuleAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
        .trackScreenSuccess()

        XCTAssertEqual(analyticsCoreManager.calls.map(\.event), [
            .screenSuccess(.category),
            .screenFailure(.categoriesList),
            .screenSuccess(.expensesList),
            .screenFailure(.expenseCategoryPicker),
            .screenSuccess(.analytics)
        ])
        XCTAssertEqual(analyticsCoreManager.calls[1].payload["error_description"] as? String, "stub-error")
        XCTAssertEqual(analyticsCoreManager.calls[3].payload["error_description"] as? String, "stub-error")
    }

    func testExpenseAIEntryAnalyticsServiceTracksSuccessAndFailureOutcomes() {
        let analyticsCoreManager = AnalyticsCoreManagingSpy()
        let sut = ExpenseAIEntryAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: AnalyticsFailurePayloadResolverSpy()
        )

        sut.trackScreenSuccess()
        sut.trackProcessSuccess(prompt: "Coffee 12", parsedExpenseCount: 2)
        sut.trackProcessFailure(prompt: "Coffee 12", error: StubError.any)
        sut.trackNoExpenseDetected(prompt: "Tea")

        XCTAssertEqual(analyticsCoreManager.calls[0].event, .screenSuccess(.expenseAIEntry))
        XCTAssertEqual(analyticsCoreManager.calls[1].event, .aiParseSuccess)
        XCTAssertEqual(analyticsCoreManager.calls[1].payload["prompt"] as? String, "Coffee 12")
        XCTAssertEqual(analyticsCoreManager.calls[1].payload["parsed_expense_count"] as? Int, 2)
        XCTAssertEqual(analyticsCoreManager.calls[2].event, .aiParseFailure)
        XCTAssertEqual(analyticsCoreManager.calls[2].payload["error_description"] as? String, "stub-error")
        XCTAssertEqual(analyticsCoreManager.calls[3].event, .aiParseFailure)
        XCTAssertEqual(analyticsCoreManager.calls[3].payload["error_description"] as? String, "no_expense_detected")
    }
}

private final class AnalyticsCoreManagingSpy: AnalyticsCoreManaging, @unchecked Sendable {
    struct Call {
        let provider: AnalyticsProvider
        let event: AnalyticsEvent
        let payload: [String: Any]
    }

    private(set) var calls: [Call] = []

    func sendEvent(provider: AnalyticsProvider, event: AnalyticsEvent, payload: [String: Any]) {
        calls.append(.init(provider: provider, event: event, payload: payload))
    }
}

private final class AnalyticsFailurePayloadResolverSpy: AnalyticsFailurePayloadResolving, @unchecked Sendable {
    func makePayload(for error: Error) -> [String: Any] {
        ["error_description": error.localizedDescription]
    }
}

private enum StubError: LocalizedError {
    case any

    var errorDescription: String? {
        "stub-error"
    }
}
