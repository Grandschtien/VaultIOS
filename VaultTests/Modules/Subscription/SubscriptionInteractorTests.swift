import XCTest
@testable import Vylok

final class SubscriptionInteractorTests: XCTestCase {
    private var presenter: SubscriptionPresentationLogicMock!
    private var router: SubscriptionRoutingLogicMock!
    private var output: SubscriptionOutputMock!
    private var storeKitService: SubscriptionServiceLogicMock!
    private var subscriptionAccessService: SubscriptionAccessServicingMock!
    private var analytics: SubscriptionAnalyticsTrackingMock!
    private var appLogService: AppLogServiceProtocolMock!
    private var sut: SubscriptionInteractor!

    override func setUp() {
        super.setUp()
        presenter = SubscriptionPresentationLogicMock()
        router = SubscriptionRoutingLogicMock()
        output = SubscriptionOutputMock()
        storeKitService = SubscriptionServiceLogicMock()
        subscriptionAccessService = SubscriptionAccessServicingMock()
        analytics = SubscriptionAnalyticsTrackingMock()
        appLogService = AppLogServiceProtocolMock()
        sut = SubscriptionInteractor(
            presenter: presenter,
            router: router,
            currentTier: .regular,
            output: output,
            storeKitService: storeKitService,
            subscriptionAccessService: subscriptionAccessService,
            pollingIntervalNanoseconds: 0,
            maximumPollingAttempts: 2,
            analytics: analytics,
            appLogService: appLogService
        )
    }

    override func tearDown() {
        sut = nil
        appLogService = nil
        analytics = nil
        subscriptionAccessService = nil
        storeKitService = nil
        output = nil
        router = nil
        presenter = nil
        super.tearDown()
    }
}

// MARK: - fetchData

extension SubscriptionInteractorTests {
    func testFetchDataWhenPlansLoadPresentsLoadedPlansAndTracksSuccess() async throws {
        // Arrange
        storeKitService.loadPlansReturnValue = Self.plans

        // Act
        await sut.fetchData()

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                SubscriptionFetchData(loadingState: .loading, currentTier: "REGULAR"),
                SubscriptionFetchData(loadingState: .loaded, currentTier: "REGULAR", plans: Self.plans)
            ]
        )
        XCTAssertEqual(analytics.trackScreenOpenCallsCount, 1)
        let successArguments = try XCTUnwrap(analytics.trackSubscriptionSuccessPlansCurrentTierReceivedInvocations.first)
        XCTAssertTrue(successArguments == (plans: Self.plans, currentTier: "REGULAR"))
    }

    func testFetchDataWhenPlansFailPresentsFailedStateAndTracksFailure() async {
        // Arrange
        storeKitService.loadPlansThrowableError = SubscriptionServiceError.emptyOfferings

        // Act
        await sut.fetchData()

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                SubscriptionFetchData(loadingState: .loading, currentTier: "REGULAR"),
                SubscriptionFetchData(
                    loadingState: .failed(
                        .undelinedError(description: SubscriptionServiceError.emptyOfferings.localizedDescription)
                    ),
                    currentTier: "REGULAR"
                )
            ]
        )
        XCTAssertEqual(
            analytics.trackSubscriptionFailureReceivedInvocations as? [SubscriptionServiceError],
            [.emptyOfferings]
        )
    }
}

// MARK: - handleTapPurchase

extension SubscriptionInteractorTests {
    func testHandleTapPurchaseWhenTierSyncsNotifiesOutputClosesAndShowsSuccess() async {
        // Arrange
        storeKitService.loadPlansReturnValue = Self.plans
        subscriptionAccessService.refreshCurrentTierSourceStateReturnValue = .network(.premium)
        await sut.fetchData()

        // Act
        await sut.handleTapPurchase(planID: Self.premiumID)

        // Assert
        XCTAssertEqual(storeKitService.purchasePlanIDReceivedInvocations, [Self.premiumID])
        XCTAssertEqual(
            Array(presenter.presentFetchedDataReceivedInvocations.dropFirst(2)),
            [
                SubscriptionFetchData(
                    loadingState: .loaded,
                    currentTier: "REGULAR",
                    plans: Self.plans,
                    purchasingPlanID: Self.premiumID
                ),
                SubscriptionFetchData(
                    loadingState: .loaded,
                    currentTier: "REGULAR",
                    plans: Self.plans,
                    purchasingPlanID: Self.premiumID,
                    isPurchaseSyncing: true
                )
            ]
        )
        XCTAssertEqual(output.handleSubscriptionDidSyncCallsCount, 1)
        XCTAssertEqual(router.closeCallsCount, 1)
        XCTAssertEqual(router.presentSuccessWithReceivedInvocations, [L10n.subscriptionReady])
    }

    func testHandleTapPurchaseLogsWholeFlowWithSingleAttemptID() async {
        // Arrange
        storeKitService.loadPlansReturnValue = Self.plans
        subscriptionAccessService.refreshCurrentTierSourceStateReturnValue = .network(.premium)
        await sut.fetchData()

        // Act
        await sut.handleTapPurchase(planID: Self.premiumID)

        // Assert
        let invocations = appLogService.logCategoryNameSourcePayloadRequestIDSubscriptionAttemptIDReceivedInvocations
        XCTAssertEqual(
            invocations.map(\.name),
            ["purchase_start", "purchase_revenuecat_result", "purchase_sync_result", "purchase_outcome"]
        )
        XCTAssertEqual(Set(invocations.compactMap(\.subscriptionAttemptID)).count, 1)
    }

    func testHandleTapPurchaseWhenTierDoesNotSyncClosesAndShowsReloadRequired() async {
        // Arrange
        storeKitService.loadPlansReturnValue = Self.plans
        subscriptionAccessService.refreshCurrentTierSourceStateReturnValue = .cache(.premium)
        await sut.fetchData()

        // Act
        await sut.handleTapPurchase(planID: Self.premiumID)

        // Assert
        XCTAssertEqual(subscriptionAccessService.refreshCurrentTierSourceStateCallsCount, 2)
        XCTAssertFalse(output.handleSubscriptionDidSyncCalled)
        XCTAssertEqual(router.closeCallsCount, 1)
        XCTAssertEqual(router.presentErrorWithReceivedInvocations, [L10n.subscriptionReloadRequired])
    }

    func testHandleTapPurchaseWhenPurchaseFailsResetsStateAndShowsError() async {
        // Arrange
        storeKitService.loadPlansReturnValue = Self.plans
        storeKitService.purchasePlanIDThrowableError = SubscriptionServiceError.purchaseCancelled
        await sut.fetchData()

        // Act
        await sut.handleTapPurchase(planID: Self.premiumID)

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations.last,
            SubscriptionFetchData(loadingState: .loaded, currentTier: "REGULAR", plans: Self.plans)
        )
        XCTAssertEqual(
            router.presentErrorWithReceivedInvocations,
            [SubscriptionServiceError.purchaseCancelled.localizedDescription]
        )
        XCTAssertEqual(analytics.trackPurchaseFailurePlanIDPlanTitleCurrentTierErrorCallsCount, 1)
        XCTAssertFalse(router.closeCalled)
    }

    func testHandleTapPurchaseWhenPlansAreNotLoadedDoesNothing() async {
        // Act
        await sut.handleTapPurchase(planID: Self.premiumID)

        // Assert
        XCTAssertFalse(storeKitService.purchasePlanIDCalled)
    }
}

// MARK: - handleTapRestorePurchase

extension SubscriptionInteractorTests {
    func testHandleTapRestorePurchaseWhenPremiumIsRestoredClosesAndShowsSuccess() async {
        // Arrange
        storeKitService.loadPlansReturnValue = Self.plans
        storeKitService.currentTier = .premium
        subscriptionAccessService.refreshCurrentTierSourceStateReturnValue = .network(.premium)
        await sut.fetchData()

        // Act
        await sut.handleTapRestorePurchase()

        // Assert
        XCTAssertEqual(storeKitService.restoreCallsCount, 1)
        XCTAssertEqual(output.handleSubscriptionDidSyncCallsCount, 1)
        XCTAssertEqual(router.closeCallsCount, 1)
        XCTAssertEqual(router.presentSuccessWithReceivedInvocations, [L10n.subscriptionRestored])
    }

    func testHandleTapRestorePurchaseWhenNothingIsRestoredShowsNotFoundMessage() async {
        // Arrange
        storeKitService.loadPlansReturnValue = Self.plans
        storeKitService.currentTier = .regular
        await sut.fetchData()

        // Act
        await sut.handleTapRestorePurchase()

        // Assert
        XCTAssertEqual(
            Array(presenter.presentFetchedDataReceivedInvocations.dropFirst(2)),
            [
                SubscriptionFetchData(
                    loadingState: .loaded,
                    currentTier: "REGULAR",
                    plans: Self.plans,
                    isRestoringPurchase: true
                ),
                SubscriptionFetchData(loadingState: .loaded, currentTier: "REGULAR", plans: Self.plans)
            ]
        )
        XCTAssertEqual(router.presentMessageWithReceivedInvocations, [L10n.subscriptionRestoreNotFound])
        XCTAssertEqual(
            appLogService.logCategoryNameSourcePayloadRequestIDSubscriptionAttemptIDReceivedInvocations.map(\.name),
            ["restore_start", "restore_revenuecat_result", "restore_outcome"]
        )
        XCTAssertFalse(router.closeCalled)
    }

    func testHandleTapRestorePurchaseWhenRestoreFailsShowsError() async {
        // Arrange
        storeKitService.loadPlansReturnValue = Self.plans
        storeKitService.restoreThrowableError = SubscriptionServiceError.failedToResolveTier
        await sut.fetchData()

        // Act
        await sut.handleTapRestorePurchase()

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations.last,
            SubscriptionFetchData(loadingState: .loaded, currentTier: "REGULAR", plans: Self.plans)
        )
        XCTAssertEqual(
            router.presentErrorWithReceivedInvocations,
            [SubscriptionServiceError.failedToResolveTier.localizedDescription]
        )
        XCTAssertFalse(router.closeCalled)
    }
}

// MARK: - handleTapClose

extension SubscriptionInteractorTests {
    func testHandleTapCloseCloses() async {
        // Act
        await sut.handleTapClose()

        // Assert
        XCTAssertEqual(router.closeCallsCount, 1)
    }
}

// MARK: - handleTapRetry

extension SubscriptionInteractorTests {
    func testHandleTapRetryReloadsPlans() async {
        // Arrange
        storeKitService.loadPlansThrowableError = SubscriptionServiceError.emptyOfferings
        await sut.fetchData()
        storeKitService.loadPlansThrowableError = nil
        storeKitService.loadPlansReturnValue = Self.plans

        // Act
        await sut.handleTapRetry()

        // Assert
        XCTAssertEqual(storeKitService.loadPlansCallsCount, 2)
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations.last,
            SubscriptionFetchData(loadingState: .loaded, currentTier: "REGULAR", plans: Self.plans)
        )
        XCTAssertEqual(analytics.trackScreenOpenCallsCount, 1)
    }
}

// MARK: - handleTapTermsOfUse

extension SubscriptionInteractorTests {
    func testHandleTapTermsOfUseOpensTerms() async {
        // Act
        await sut.handleTapTermsOfUse()

        // Assert
        XCTAssertEqual(router.openTermsOfUseCallsCount, 1)
    }
}

// MARK: - handleTapPrivacyPolicy

extension SubscriptionInteractorTests {
    func testHandleTapPrivacyPolicyOpensPrivacyPolicy() async {
        // Act
        await sut.handleTapPrivacyPolicy()

        // Assert
        XCTAssertEqual(router.openPrivacyPolicyCallsCount, 1)
    }
}

private extension SubscriptionInteractorTests {
    static let premiumID = SubscriptionCatalog.premium.id
    static let plans = [
        SubscriptionFetchData.SubscriptionStorePlan(id: premiumID, title: "Premium", price: "$4.99")
    ]
}
