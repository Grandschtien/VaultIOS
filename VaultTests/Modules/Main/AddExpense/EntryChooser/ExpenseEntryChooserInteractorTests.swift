import XCTest
@testable import Vylok

@MainActor
final class ExpenseEntryChooserInteractorTests: XCTestCase {
    private var presenter: ExpenseEntryChooserPresentationLogicMock!
    private var router: ExpenseEntryChooserRoutingLogicMock!
    private var subscriptionAccessService: SubscriptionAccessServicingMock!

    override func setUp() {
        super.setUp()
        presenter = ExpenseEntryChooserPresentationLogicMock()
        router = ExpenseEntryChooserRoutingLogicMock()
        subscriptionAccessService = SubscriptionAccessServicingMock()
    }

    override func tearDown() {
        subscriptionAccessService = nil
        router = nil
        presenter = nil
        super.tearDown()
    }
}

// MARK: - fetchData

extension ExpenseEntryChooserInteractorTests {
    func testFetchDataPresentsDefaultTitle() async {
        // Arrange
        let sut = ExpenseEntryChooserInteractor(
            presenter: presenter,
            router: router,
            subscriptionAccessService: subscriptionAccessService
        )

        // Act
        await sut.fetchData()

        // Assert
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.map(\.title), [L10n.mainAddExpenseTitle])
    }
}

// MARK: - handleTapAiEntry

extension ExpenseEntryChooserInteractorTests {
    func testHandleTapAiEntryWhenSubscriptionHasAiInputOpensAiEntry() async {
        // Arrange
        let sut = ExpenseEntryChooserInteractor(
            presenter: presenter,
            router: router,
            subscriptionAccessService: subscriptionAccessService
        )
        subscriptionAccessService.currentSubscriptionSnapshotReturnValue = SubscriptionAccessSnapshotFixtures.makeSnapshot(
            tier: .regular,
            capabilities: [.aiInput]
        )

        // Act
        await sut.handleTapAiEntry()

        // Assert
        XCTAssertEqual(router.openAiEntryCallsCount, 1)
        XCTAssertFalse(router.openSubscriptionCurrentTierOutputCalled)
    }

    func testHandleTapAiEntryWhenSubscriptionHasNoAiInputOpensSubscription() async {
        // Arrange
        let sut = ExpenseEntryChooserInteractor(
            presenter: presenter,
            router: router,
            subscriptionAccessService: subscriptionAccessService
        )
        subscriptionAccessService.currentSubscriptionSnapshotReturnValue = SubscriptionAccessSnapshotFixtures.makeSnapshot(
            tier: .regular,
            capabilities: []
        )

        // Act
        await sut.handleTapAiEntry()

        // Assert
        XCTAssertFalse(router.openAiEntryCalled)
        XCTAssertEqual(router.openSubscriptionCurrentTierOutputReceivedInvocations.map(\.currentTier), [.regular])
    }

    func testHandleTapAiEntryWhenSnapshotIsMissingOpensSubscriptionWithRegularTier() async {
        // Arrange
        let sut = ExpenseEntryChooserInteractor(
            presenter: presenter,
            router: router,
            subscriptionAccessService: subscriptionAccessService
        )

        // Act
        await sut.handleTapAiEntry()

        // Assert
        XCTAssertFalse(router.openAiEntryCalled)
        XCTAssertEqual(router.openSubscriptionCurrentTierOutputReceivedInvocations.map(\.currentTier), [.regular])
    }
}

// MARK: - handleTapManualEntry

extension ExpenseEntryChooserInteractorTests {
    func testHandleTapManualEntryOpensManualEntry() async {
        // Arrange
        let sut = ExpenseEntryChooserInteractor(
            presenter: presenter,
            router: router,
            subscriptionAccessService: subscriptionAccessService
        )

        // Act
        await sut.handleTapManualEntry()

        // Assert
        XCTAssertEqual(router.openManualEntryCallsCount, 1)
    }
}

// MARK: - handleTapClose

extension ExpenseEntryChooserInteractorTests {
    func testHandleTapCloseClosesSheet() async {
        // Arrange
        let sut = ExpenseEntryChooserInteractor(
            presenter: presenter,
            router: router,
            subscriptionAccessService: subscriptionAccessService
        )

        // Act
        await sut.handleTapClose()

        // Assert
        XCTAssertEqual(router.closeCallsCount, 1)
    }
}
