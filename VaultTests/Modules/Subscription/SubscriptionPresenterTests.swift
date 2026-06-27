import XCTest
@testable import Vylok

@MainActor
final class SubscriptionPresenterTests: XCTestCase {
    private var sut: SubscriptionPresenter!
    private var handler: SubscriptionHandlerSpy!

    override func setUp() {
        super.setUp()
        handler = SubscriptionHandlerSpy()
        sut = SubscriptionPresenter(viewModel: .init())
        sut.handler = handler
    }

    override func tearDown() {
        handler = nil
        sut = nil
        super.tearDown()
    }
}

extension SubscriptionPresenterTests {
    func testPresentFetchedDataLoadingBuildsLoadingState() {
        sut.presentFetchedData(
            .init(loadingState: .loading)
        )

        XCTAssertEqual(sut.viewModel.header.title.text, L10n.subscriptionTitle)

        guard case .loading = sut.viewModel.state else {
            return XCTFail("Expected loading state")
        }
    }
}

extension SubscriptionPresenterTests {
    func testPresentFetchedDataLegacyPaidTierMapsToPremiumCurrentPlan() {
        sut.presentFetchedData(
            .init(
                loadingState: .loaded,
                currentTier: "PLUS",
                plans: [
                    .init(
                        id: SubscriptionCatalog.premium.id,
                        title: L10n.subscriptionPremium,
                        price: "$2.99"
                    )
                ]
            )
        )

        guard case let .loaded(content) = sut.viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertEqual(content.title.text, L10n.subscriptionSubtitle)
        XCTAssertEqual(content.currentPlan.title.text, L10n.subscriptionCurrentPlan)
        XCTAssertEqual(content.currentPlan.planTitle.text, L10n.subscriptionPremium)
        XCTAssertEqual(content.currentPlan.description.text, L10n.subscriptionPremiumDescription)
        XCTAssertTrue(content.plans.isEmpty)
    }
}

extension SubscriptionPresenterTests {
    func testPresentFetchedDataRegularTierMapsToFreeCurrentPlan() {
        sut.presentFetchedData(
            .init(
                loadingState: .loaded,
                currentTier: "REGULAR",
                plans: [
                    .init(
                        id: SubscriptionCatalog.premium.id,
                        title: L10n.subscriptionPremium,
                        price: "$2.99"
                    )
                ]
            )
        )

        guard case let .loaded(content) = sut.viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertEqual(content.currentPlan.planTitle.text, L10n.subscriptionFree)
        XCTAssertEqual(content.currentPlan.description.text, L10n.subscriptionFreeDescription)
        XCTAssertEqual(content.plans.map(\.title.text), [L10n.subscriptionPremium])
        XCTAssertEqual(content.plans.map(\.price.text), [L10n.subscriptionPerMonth("$2.99")])
        XCTAssertEqual(content.restoreButton.title, L10n.subscriptionRestorePurchase)
        XCTAssertEqual(content.termsOfUseLink.title.text, L10n.subscriptionTermsOfUse)
        XCTAssertEqual(content.privacyPolicyLink.title.text, L10n.subscriptionPrivacyPolicy)
    }
}

extension SubscriptionPresenterTests {
    func testPresentFetchedDataPurchasingDisablesCloseAndShowsOverlayImmediately() {
        sut.presentFetchedData(
            .init(
                loadingState: .loaded,
                plans: [
                    .init(
                        id: SubscriptionCatalog.premium.id,
                        title: L10n.subscriptionPremium,
                        price: "$2.99"
                    )
                ],
                purchasingPlanID: SubscriptionCatalog.premium.id
            )
        )

        XCTAssertFalse(sut.viewModel.header.isCloseEnabled)
        XCTAssertTrue(sut.viewModel.isDismissLocked)
        XCTAssertTrue(sut.viewModel.isOverlayLoading)
        XCTAssertEqual(
            sut.viewModel.overlayMessage?.text,
            L10n.subscriptionPurchaseProcessing
        )

        guard case let .loaded(content) = sut.viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertTrue(content.plans[0].button.isLoading)
    }
}

extension SubscriptionPresenterTests {
    func testPresentFetchedDataRestoringDisablesCloseAndShowsRestoreLoader() {
        sut.presentFetchedData(
            .init(
                loadingState: .loaded,
                plans: [
                    .init(
                        id: SubscriptionCatalog.premium.id,
                        title: L10n.subscriptionPremium,
                        price: "$2.99"
                    )
                ],
                isRestoringPurchase: true
            )
        )

        XCTAssertFalse(sut.viewModel.header.isCloseEnabled)
        XCTAssertTrue(sut.viewModel.isDismissLocked)
        XCTAssertFalse(sut.viewModel.isOverlayLoading)
        XCTAssertNil(sut.viewModel.overlayMessage)

        guard case let .loaded(content) = sut.viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertTrue(content.restoreButton.isLoading)
        XCTAssertFalse(content.plans[0].button.isEnabled)
    }
}

extension SubscriptionPresenterTests {
    func testPresentFetchedDataRestoreCommandCallsHandler() async {
        let restoreExpectation = expectation(description: "Restore command")
        handler.onHandleRestorePurchase = {
            restoreExpectation.fulfill()
        }

        sut.presentFetchedData(
            .init(
                loadingState: .loaded,
                plans: [
                    .init(
                        id: SubscriptionCatalog.premium.id,
                        title: L10n.subscriptionPremium,
                        price: "$2.99"
                    )
                ]
            )
        )

        guard case let .loaded(content) = sut.viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        content.restoreButton.tapCommand.execute()

        await fulfillment(of: [restoreExpectation], timeout: 1.0)
    }
}

extension SubscriptionPresenterTests {
    func testPresentFetchedDataLegalLinkCommandsCallHandler() async {
        let termsExpectation = expectation(description: "Terms command")
        let privacyExpectation = expectation(description: "Privacy command")
        handler.onHandleTermsOfUse = {
            termsExpectation.fulfill()
        }
        handler.onHandlePrivacyPolicy = {
            privacyExpectation.fulfill()
        }

        sut.presentFetchedData(
            .init(
                loadingState: .loaded,
                plans: [
                    .init(
                        id: SubscriptionCatalog.premium.id,
                        title: L10n.subscriptionPremium,
                        price: "$2.99"
                    )
                ]
            )
        )

        guard case let .loaded(content) = sut.viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        content.termsOfUseLink.tapCommand.execute()
        content.privacyPolicyLink.tapCommand.execute()

        await fulfillment(of: [termsExpectation, privacyExpectation], timeout: 1.0)
    }
}

extension SubscriptionPresenterTests {
    func testPresentFetchedDataFailedBuildsRetryState() async {
        let retryExpectation = expectation(description: "Retry command")
        handler.onHandleRetry = {
            retryExpectation.fulfill()
        }

        sut.presentFetchedData(
            .init(
                loadingState: .failed(.undelinedError(description: "load failed"))
            )
        )

        guard case let .error(errorViewModel) = sut.viewModel.state else {
            return XCTFail("Expected error state")
        }

        XCTAssertEqual(errorViewModel.title.text, L10n.subscriptionLoadingFailed)
        errorViewModel.tapCommand.execute()

        await fulfillment(of: [retryExpectation], timeout: 1.0)
    }
}

private final class SubscriptionHandlerSpy: SubscriptionHandler, @unchecked Sendable {
    var onHandleRetry: (() -> Void)?
    var onHandleRestorePurchase: (() -> Void)?
    var onHandleTermsOfUse: (() -> Void)?
    var onHandlePrivacyPolicy: (() -> Void)?

    func handleTapClose() async {}

    func handleTapRetry() async {
        onHandleRetry?()
    }

    func handleTapPurchase(planID: String) async {}

    func handleTapRestorePurchase() async {
        onHandleRestorePurchase?()
    }

    func handleTapTermsOfUse() async {
        onHandleTermsOfUse?()
    }

    func handleTapPrivacyPolicy() async {
        onHandlePrivacyPolicy?()
    }
}
