import XCTest
@testable import Vylok

final class ModuleAnalyticsTrackingTests: XCTestCase {
    func testAuthAnalyticsServicesSendExpectedEvents() {
        let analyticsCoreManager = AnalyticsCoreManagingMock()
        let failurePayloadResolver = AnalyticsFailurePayloadResolvingMock()
        failurePayloadResolver.makePayloadForReturnValue = ["error_description": "stub-error"]

        LoginAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
        .trackLoginSuccess()
        RegistrationAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
        .trackRegistrationFailure(TestError.any)
        ForgotPasswordAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
        .trackScreenOpen()

        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations.map(\.event), [
            .screenSuccess(.login),
            .screenFailure(.registration),
            .screenOpen(.forgotPassword)
        ])
    }

    func testProfileAnalyticsServiceBuildsCurrencyAndPaywallPayload() {
        let analyticsCoreManager = AnalyticsCoreManagingMock()
        let failurePayloadResolver = AnalyticsFailurePayloadResolvingMock()
        failurePayloadResolver.makePayloadForReturnValue = ["error_description": "stub-error"]
        let sut = ProfileAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )

        sut.trackCurrencySaveSuccess(previousCurrencyCode: "USD", updatedCurrencyCode: "EUR")
        sut.trackPaywallOpen(currentTier: "PREMIUM")

        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[0].event, .screenSuccess(.profileCurrency))
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[0].payload["previous_currency_code"] as? String, "USD")
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[0].payload["updated_currency_code"] as? String, "EUR")
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[1].event, .paywallOpen(source: .profile))
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[1].payload["source_screen"] as? String, AnalyticsScreen.profile.rawValue)
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[1].payload["current_tier"] as? String, "PREMIUM")
    }

    func testSubscriptionAnalyticsServiceBuildsPlanPayload() {
        let analyticsCoreManager = AnalyticsCoreManagingMock()
        let failurePayloadResolver = AnalyticsFailurePayloadResolvingMock()
        failurePayloadResolver.makePayloadForReturnValue = ["error_description": "stub-error"]
        let sut = SubscriptionAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )

        sut.trackSubscriptionSuccess(
            plans: [
                .init(id: "plan.a", title: "Plan A", price: "$1"),
                .init(id: "plan.b", title: "Plan B", price: "$2")
            ],
            currentTier: "FREE"
        )
        sut.trackPurchaseFailure(planID: "plan.a", planTitle: "Plan A", currentTier: "FREE", error: TestError.any)

        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[0].event, .screenSuccess(.subscription))
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[0].payload["plan_count"] as? Int, 2)
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[0].payload["plan_ids_csv"] as? String, "plan.a,plan.b")
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[1].event, .subscriptionPurchaseFailure)
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[1].payload["plan_id"] as? String, "plan.a")
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[1].payload["plan_title"] as? String, "Plan A")
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[1].payload["error_description"] as? String, "stub-error")
    }

    func testMainFlowAnalyticsServicesSendExpectedScreenOpenEvents() {
        let analyticsCoreManager = AnalyticsCoreManagingMock()
        let failurePayloadResolver = AnalyticsFailurePayloadResolvingMock()
        failurePayloadResolver.makePayloadForReturnValue = ["error_description": "stub-error"]

        MainAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager
        )
            .trackScreenOpen()
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

        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations.map(\.event), [
            .screenOpen(.main),
            .screenOpen(.category),
            .screenOpen(.expenseCategoryPicker),
            .screenOpen(.categoriesList),
            .screenOpen(.expensesList),
            .screenOpen(.analytics)
        ])
    }

    func testExpenseAIEntryAnalyticsServiceTracksOpenMicrophoneAndConfirmTap() {
        let analyticsCoreManager = AnalyticsCoreManagingMock()
        let failurePayloadResolver = AnalyticsFailurePayloadResolvingMock()
        failurePayloadResolver.makePayloadForReturnValue = ["error_description": "stub-error"]
        let sut = ExpenseAIEntryAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )

        sut.trackScreenOpen()
        sut.trackMicrophoneTap()
        sut.trackConfirmTap(prompt: "Coffee 12")

        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[0].event, .screenOpen(.expenseAIEntry))
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[1].event, .tap(.aiMicrophoneTap))
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[2].event, .tap(.aiConfirmTap))
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[2].payload["prompt"] as? String, "Coffee 12")
    }

    func testMainFlowAnalyticsServicesSendSuccessAndFailureEvents() {
        let analyticsCoreManager = AnalyticsCoreManagingMock()
        let failurePayloadResolver = AnalyticsFailurePayloadResolvingMock()
        failurePayloadResolver.makePayloadForReturnValue = ["error_description": "stub-error"]

        CategoryAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
        .trackScreenSuccess()
        CategoriesListAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
        .trackScreenFailure(TestError.any)
        ExpesiesListAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
        .trackScreenSuccess()
        ExpenseCategoryPickerAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
        .trackScreenFailure(TestError.any)
        AnalyticsModuleAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )
        .trackScreenSuccess()

        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations.map(\.event), [
            .screenSuccess(.category),
            .screenFailure(.categoriesList),
            .screenSuccess(.expensesList),
            .screenFailure(.expenseCategoryPicker),
            .screenSuccess(.analytics)
        ])
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[1].payload["error_description"] as? String, "stub-error")
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[3].payload["error_description"] as? String, "stub-error")
    }

    func testExpenseAIEntryAnalyticsServiceTracksSuccessAndFailureOutcomes() {
        let analyticsCoreManager = AnalyticsCoreManagingMock()
        let failurePayloadResolver = AnalyticsFailurePayloadResolvingMock()
        failurePayloadResolver.makePayloadForReturnValue = ["error_description": "stub-error"]
        let sut = ExpenseAIEntryAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: failurePayloadResolver
        )

        sut.trackScreenSuccess()
        sut.trackProcessSuccess(prompt: "Coffee 12", parsedExpenseCount: 2)
        sut.trackProcessFailure(prompt: "Coffee 12", error: TestError.any)
        sut.trackNoExpenseDetected(prompt: "Tea")

        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[0].event, .screenSuccess(.expenseAIEntry))
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[1].event, .aiParseSuccess)
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[1].payload["prompt"] as? String, "Coffee 12")
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[1].payload["parsed_expense_count"] as? Int, 2)
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[2].event, .aiParseFailure)
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[2].payload["error_description"] as? String, "stub-error")
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[3].event, .aiParseFailure)
        XCTAssertEqual(analyticsCoreManager.sendEventProviderEventPayloadReceivedInvocations[3].payload["error_description"] as? String, "no_expense_detected")
    }
}
