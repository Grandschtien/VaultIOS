import XCTest
@testable import Vault

@MainActor
final class ExpenseEntryChooserInteractorTests: XCTestCase {
    func testFetchDataPresentsDefaultTitle() async {
        let presenter = ExpenseEntryChooserPresenterSpy()
        let router = ExpenseEntryChooserRouterSpy()
        let sut = ExpenseEntryChooserInteractor(
            presenter: presenter,
            router: router,
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "PLUS")
        )

        await sut.fetchData()

        XCTAssertEqual(presenter.presentedData.last?.title, L10n.mainAddExpenseTitle)
    }

    func testHandleTapAiEntryRoutesToAiScreen() async {
        let router = ExpenseEntryChooserRouterSpy()
        let sut = ExpenseEntryChooserInteractor(
            presenter: ExpenseEntryChooserPresenterSpy(),
            router: router,
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "PLUS")
        )

        await sut.handleTapAiEntry()

        XCTAssertEqual(router.openAiEntryCallsCount, 1)
    }

    func testHandleTapAiEntryWithRegularTierRoutesToSubscription() async {
        let router = ExpenseEntryChooserRouterSpy()
        let sut = ExpenseEntryChooserInteractor(
            presenter: ExpenseEntryChooserPresenterSpy(),
            router: router,
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "REGULAR")
        )

        await sut.handleTapAiEntry()

        XCTAssertEqual(router.openAiEntryCallsCount, 0)
        XCTAssertEqual(router.lastOpenedSubscriptionTier, "REGULAR")
    }

    func testHandleTapManualEntryRoutesToManualScreen() async {
        let router = ExpenseEntryChooserRouterSpy()
        let sut = ExpenseEntryChooserInteractor(
            presenter: ExpenseEntryChooserPresenterSpy(),
            router: router,
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "PLUS")
        )

        await sut.handleTapManualEntry()

        XCTAssertEqual(router.openManualEntryCallsCount, 1)
    }

    func testHandleTapCloseDismissesSheet() async {
        let router = ExpenseEntryChooserRouterSpy()
        let sut = ExpenseEntryChooserInteractor(
            presenter: ExpenseEntryChooserPresenterSpy(),
            router: router,
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "PLUS")
        )

        await sut.handleTapClose()

        XCTAssertEqual(router.closeCallsCount, 1)
    }
}

@MainActor
private final class ExpenseEntryChooserPresenterSpy: ExpenseEntryChooserPresentationLogic {
    private(set) var presentedData: [ExpenseEntryChooserFetchData] = []

    func presentFetchedData(_ data: ExpenseEntryChooserFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class ExpenseEntryChooserRouterSpy: ExpenseEntryChooserRoutingLogic {
    private(set) var openAiEntryCallsCount = 0
    private(set) var openManualEntryCallsCount = 0
    private(set) var closeCallsCount = 0
    private(set) var lastOpenedSubscriptionTier: String?

    func openAiEntry() {
        openAiEntryCallsCount += 1
    }

    func openManualEntry() {
        openManualEntryCallsCount += 1
    }

    func openSubscription(
        currentTier: String,
        output: SubscriptionOutput
    ) {
        lastOpenedSubscriptionTier = currentTier
    }

    func close() {
        closeCallsCount += 1
    }
}

private actor SubscriptionAccessServiceStub: SubscriptionAccessServicing {
    private let tier: String

    init(currentTier: String) {
        tier = currentTier
    }

    func currentTierState() async -> SubscriptionTierState {
        .resolved(tier)
    }

    func refreshCurrentTierState() async -> SubscriptionTierState {
        .resolved(tier)
    }
}
