import XCTest
@testable import Vault

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
    func testPresentFetchedDataLoadedMapsPlans() {
        sut.presentFetchedData(
            .init(
                loadingState: .loaded,
                currentTier: "PREMIUM",
                plans: [
                    .init(
                        id: SubscriptionCatalog.plus.id,
                        title: L10n.subscriptionPlus,
                        price: "$1.99"
                    ),
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
        XCTAssertEqual(content.plans.count, 1)
        XCTAssertEqual(content.plans[0].title.text, L10n.subscriptionPlus)
        XCTAssertEqual(content.plans[0].description.text, L10n.subscriptionPlusDescription)
        XCTAssertEqual(content.plans[0].price.text, L10n.subscriptionPerMonth("$1.99"))
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
                        id: SubscriptionCatalog.plus.id,
                        title: L10n.subscriptionPlus,
                        price: "$1.99"
                    ),
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
        XCTAssertEqual(content.plans.map(\.title.text), [L10n.subscriptionPlus, L10n.subscriptionPremium])
    }
}

extension SubscriptionPresenterTests {
    func testPresentFetchedDataPurchasingDisablesCloseAndShowsLoader() {
        sut.presentFetchedData(
            .init(
                loadingState: .loaded,
                plans: [
                    .init(
                        id: SubscriptionCatalog.plus.id,
                        title: L10n.subscriptionPlus,
                        price: "$1.99"
                    ),
                    .init(
                        id: SubscriptionCatalog.premium.id,
                        title: L10n.subscriptionPremium,
                        price: "$2.99"
                    )
                ],
                purchasingPlanID: SubscriptionCatalog.plus.id
            )
        )

        XCTAssertFalse(sut.viewModel.header.isCloseEnabled)

        guard case let .loaded(content) = sut.viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertTrue(content.plans[0].button.isLoading)
        XCTAssertFalse(content.plans[1].button.isEnabled)
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

    func handleTapClose() async {}

    func handleTapRetry() async {
        onHandleRetry?()
    }

    func handleTapPurchase(planID: String) async {}
}
