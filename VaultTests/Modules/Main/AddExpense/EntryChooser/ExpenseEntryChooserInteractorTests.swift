import XCTest
@testable import Vylok

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
        XCTAssertEqual(router.lastOpenedSubscriptionTier, .regular)
    }

    func testHandleTapAiEntryUsesCapabilityInsteadOfTier() async {
        let router = ExpenseEntryChooserRouterSpy()
        let sut = ExpenseEntryChooserInteractor(
            presenter: ExpenseEntryChooserPresenterSpy(),
            router: router,
            subscriptionAccessService: SubscriptionAccessServiceStub(
                currentTier: "REGULAR",
                snapshot: .init(
                    tier: .regular,
                    status: .active,
                    paidAccessUntil: nil,
                    capabilities: [.aiInput],
                    aiRequestsLimit: 300,
                    aiRequestsRemaining: 5,
                    statusVersion: 42
                )
            )
        )

        await sut.handleTapAiEntry()

        XCTAssertEqual(router.openAiEntryCallsCount, 1)
        XCTAssertNil(router.lastOpenedSubscriptionTier)
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
    private(set) var lastOpenedSubscriptionTier: SubscriptionTier?

    func openAiEntry() {
        openAiEntryCallsCount += 1
    }

    func openManualEntry() {
        openManualEntryCallsCount += 1
    }

    func openSubscription(
        currentTier: SubscriptionTier,
        output: SubscriptionOutput
    ) {
        lastOpenedSubscriptionTier = currentTier
    }

    func close() {
        closeCallsCount += 1
    }
}

private actor SubscriptionAccessServiceStub: SubscriptionAccessServicing {
    private let snapshot: SubscriptionAccessSnapshot

    init(
        currentTier: String,
        snapshot: SubscriptionAccessSnapshot? = nil
    ) {
        self.snapshot = snapshot ?? Self.makeSnapshot(tier: currentTier)
    }

    func currentTierState() async -> SubscriptionTierState {
        .resolved(snapshot.tier)
    }

    func refreshCurrentTierState() async -> SubscriptionTierState {
        .resolved(snapshot.tier)
    }

    func refreshCurrentTierSourceState() async -> SubscriptionTierRefreshState {
        .network(snapshot.tier)
    }

    func currentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot? {
        snapshot
    }

    func refreshCurrentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot? {
        snapshot
    }

    nonisolated private static func makeSnapshot(tier: String) -> SubscriptionAccessSnapshot {
        let capabilities: [SubscriptionCapability] = switch tier {
        case "PREMIUM", "PLUS", "ACTIVE":
            [
                SubscriptionCapability.analytics,
                .customDateRange,
                .aiInput
            ]
        default:
            []
        }

        return SubscriptionAccessSnapshot(
            tier: tier == "REGULAR" ? .regular : .premium,
            status: .active,
            paidAccessUntil: nil,
            capabilities: capabilities,
            aiRequestsLimit: capabilities.isEmpty ? 0 : 300,
            aiRequestsRemaining: capabilities.isEmpty ? 0 : 300,
            statusVersion: 42
        )
    }
}
