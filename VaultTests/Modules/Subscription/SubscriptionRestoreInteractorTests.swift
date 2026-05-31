import XCTest
@testable import Vault

@MainActor
final class SubscriptionRestoreInteractorTests: XCTestCase {
    func testHandleTapRestorePurchaseWithActiveSubscriptionClosesAndShowsSuccess() async {
        let presenter = SubscriptionPresenterSpy()
        let router = SubscriptionRouterSpy()
        let output = SubscriptionOutputSpy()
        let storeKitService = SubscriptionServiceStub(
            loadPlansResult: .success(defaultPlans),
            restoredTier: .premium
        )
        let subscriptionAccessService = SubscriptionAccessServiceStub(
            refreshedTierStates: [.network("PREMIUM")]
        )
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            storeKitService: storeKitService,
            subscriptionAccessService: subscriptionAccessService
        )

        await sut.fetchData()
        await sut.handleTapRestorePurchase()

        XCTAssertEqual(await storeKitService.restoreCallsCount(), 1)
        XCTAssertEqual(await output.callsCount(), 1)
        XCTAssertEqual(router.closeCallsCount, 1)
        XCTAssertEqual(router.presentedSuccessMessages, [L10n.subscriptionRestored])
    }
}

extension SubscriptionRestoreInteractorTests {
    func testHandleTapRestorePurchaseWithoutActiveSubscriptionShowsMessage() async {
        let presenter = SubscriptionPresenterSpy()
        let router = SubscriptionRouterSpy()
        let output = SubscriptionOutputSpy()
        let storeKitService = SubscriptionServiceStub(
            loadPlansResult: .success(defaultPlans),
            restoredTier: .none
        )
        let subscriptionAccessService = SubscriptionAccessServiceStub()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            storeKitService: storeKitService,
            subscriptionAccessService: subscriptionAccessService
        )

        await sut.fetchData()
        await sut.handleTapRestorePurchase()

        XCTAssertEqual(await output.callsCount(), 0)
        XCTAssertEqual(router.closeCallsCount, 0)
        XCTAssertEqual(router.presentedMessages, [L10n.subscriptionRestoreNotFound])
        XCTAssertEqual(await subscriptionAccessService.refreshCallsCount(), 0)
        XCTAssertFalse(presenter.presentedData.last?.isRestoringPurchase ?? true)
    }
}

extension SubscriptionRestoreInteractorTests {
    func testHandleTapRestorePurchaseFailureShowsErrorAndResetsLoadingState() async {
        let presenter = SubscriptionPresenterSpy()
        let router = SubscriptionRouterSpy()
        let output = SubscriptionOutputSpy()
        let storeKitService = SubscriptionServiceStub(
            loadPlansResult: .success(defaultPlans),
            restoreResult: .failure(SilentError())
        )
        let subscriptionAccessService = SubscriptionAccessServiceStub()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            storeKitService: storeKitService,
            subscriptionAccessService: subscriptionAccessService
        )

        await sut.fetchData()
        await sut.handleTapRestorePurchase()

        XCTAssertEqual(await output.callsCount(), 0)
        XCTAssertEqual(router.presentedErrors, [L10n.subscriptionRestoreFailed])
        XCTAssertFalse(presenter.presentedData.last?.isRestoringPurchase ?? true)
    }
}

private extension SubscriptionRestoreInteractorTests {
    var defaultPlans: [SubscriptionFetchData.SubscriptionStorePlan] {
        [
            .init(
                id: SubscriptionCatalog.premium.id,
                title: L10n.subscriptionPremium,
                price: "$2.99"
            )
        ]
    }

    func makeSut(
        presenter: SubscriptionPresentationLogic,
        router: SubscriptionRoutingLogic,
        output: SubscriptionOutput,
        storeKitService: SubscriptionServiceLogic,
        subscriptionAccessService: SubscriptionAccessServicing
    ) -> SubscriptionInteractor {
        SubscriptionInteractor(
            presenter: presenter,
            router: router,
            currentTier: "REGULAR",
            output: output,
            storeKitService: storeKitService,
            subscriptionAccessService: subscriptionAccessService,
            pollingIntervalNanoseconds: .zero,
            maximumPollingAttempts: 1
        )
    }
}

@MainActor
private final class SubscriptionPresenterSpy: SubscriptionPresentationLogic {
    private(set) var presentedData: [SubscriptionFetchData] = []

    func presentFetchedData(_ data: SubscriptionFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class SubscriptionRouterSpy: SubscriptionRoutingLogic {
    private(set) var closeCallsCount = 0
    private(set) var presentedErrors: [String] = []
    private(set) var presentedMessages: [String] = []
    private(set) var presentedSuccessMessages: [String] = []

    func close() {
        closeCallsCount += 1
    }

    func presentError(with text: String) {
        presentedErrors.append(text)
    }

    func presentMessage(with text: String) {
        presentedMessages.append(text)
    }

    func presentSuccess(with text: String) {
        presentedSuccessMessages.append(text)
    }
}

private actor SubscriptionOutputSpy: SubscriptionOutput {
    private var didSyncCallsCount = 0

    func handleSubscriptionDidSync() async {
        didSyncCallsCount += 1
    }

    func callsCount() -> Int {
        didSyncCallsCount
    }
}

private actor SubscriptionAccessServiceStub: SubscriptionAccessServicing {
    private let refreshedTierStates: [SubscriptionTierRefreshState]
    private var refreshCalls = 0

    init(refreshedTierStates: [SubscriptionTierRefreshState] = []) {
        self.refreshedTierStates = refreshedTierStates
    }

    func currentTierState() async -> SubscriptionTierState {
        .resolved("REGULAR")
    }

    func refreshCurrentTierState() async -> SubscriptionTierState {
        .resolved("REGULAR")
    }

    func refreshCurrentTierSourceState() async -> SubscriptionTierRefreshState {
        let index = min(refreshCalls, max(refreshedTierStates.count - 1, .zero))
        refreshCalls += 1

        guard !refreshedTierStates.isEmpty else {
            return .unavailable
        }

        return refreshedTierStates[index]
    }

    func refreshCallsCount() -> Int {
        refreshCalls
    }
}

private final class SubscriptionServiceStub: SubscriptionServiceLogic, @unchecked Sendable {
    var currentTier: SubscriptionTier = .none
    var loadedPlans: [SubscriptionFetchData.SubscriptionStorePlan] = []

    private let loadPlansResult: Result<[SubscriptionFetchData.SubscriptionStorePlan], Error>
    private let restoreResult: Result<Void, Error>
    private let restoredTier: SubscriptionTier
    private let state = State()

    init(
        loadPlansResult: Result<[SubscriptionFetchData.SubscriptionStorePlan], Error>,
        restoreResult: Result<Void, Error> = .success(()),
        restoredTier: SubscriptionTier = .none
    ) {
        self.loadPlansResult = loadPlansResult
        self.restoreResult = restoreResult
        self.restoredTier = restoredTier
    }

    func loadPlans() async throws -> [SubscriptionFetchData.SubscriptionStorePlan] {
        let plans = try loadPlansResult.get()
        loadedPlans = plans
        return plans
    }

    func purchase(planID: String) async throws {}

    func restore() async throws {
        await state.incrementRestoreCallsCount()
        try restoreResult.get()
        currentTier = restoredTier
    }

    func refreshCurrentTier() async throws {}

    func manualSync() async throws {}

    func restoreCallsCount() async -> Int {
        await state.restoreCallsCount()
    }
}

private extension SubscriptionServiceStub {
    actor State {
        private var recordedRestoreCallsCount = 0

        func incrementRestoreCallsCount() {
            recordedRestoreCallsCount += 1
        }

        func restoreCallsCount() -> Int {
            recordedRestoreCallsCount
        }
    }
}

private struct SilentError: LocalizedError {
    var errorDescription: String? { "" }
}
