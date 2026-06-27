import XCTest
@testable import Vylok

@MainActor
final class SubscriptionLoggingTests: XCTestCase {
    func testHandleTapPurchaseLogsSingleAttemptIDAcrossSuccessFlow() async {
        let presenter = SubscriptionLoggingPresenterSpy()
        let router = SubscriptionLoggingRouterSpy()
        let output = SubscriptionLoggingOutputSpy()
        let storeKitService = SubscriptionLoggingServiceStub(
            loadPlansResult: .success(defaultPlans),
            purchaseError: nil,
            restoredTier: .premium
        )
        let subscriptionAccessService = SubscriptionLoggingAccessServiceStub(
            refreshedTierStates: [.network(.premium)]
        )
        let appLogService = AppLogServiceSpy()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            storeKitService: storeKitService,
            subscriptionAccessService: subscriptionAccessService,
            appLogService: appLogService
        )

        await sut.fetchData()
        await sut.handleTapPurchase(planID: SubscriptionCatalog.premium.id)

        await waitForEntries(expected: 4, service: appLogService)
        let entries = await appLogService.entries().filter { $0.source == "SubscriptionInteractor" }
        let names = entries.map(\.name)
        let attemptIDs = Set(entries.compactMap(\.subscription_attempt_id))

        XCTAssertEqual(
            names,
            ["purchase_start", "purchase_revenuecat_result", "purchase_sync_result", "purchase_outcome"]
        )
        XCTAssertEqual(attemptIDs.count, 1)
        XCTAssertEqual(entries.last?.payload["result"], .string("success"))
        XCTAssertEqual(await output.callsCount(), 1)
        XCTAssertEqual(router.closeCallsCount, 1)
    }

    func testHandleTapRestorePurchaseLogsNotFoundOutcomeWithSingleAttemptID() async {
        let presenter = SubscriptionLoggingPresenterSpy()
        let router = SubscriptionLoggingRouterSpy()
        let output = SubscriptionLoggingOutputSpy()
        let storeKitService = SubscriptionLoggingServiceStub(
            loadPlansResult: .success(defaultPlans),
            purchaseError: nil,
            restoredTier: .regular
        )
        let subscriptionAccessService = SubscriptionLoggingAccessServiceStub()
        let appLogService = AppLogServiceSpy()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            storeKitService: storeKitService,
            subscriptionAccessService: subscriptionAccessService,
            appLogService: appLogService
        )

        await sut.fetchData()
        await sut.handleTapRestorePurchase()

        await waitForEntries(expected: 3, service: appLogService)
        let entries = await appLogService.entries().filter { $0.source == "SubscriptionInteractor" }
        let names = entries.map(\.name)
        let attemptIDs = Set(entries.compactMap(\.subscription_attempt_id))

        XCTAssertEqual(
            names,
            ["restore_start", "restore_revenuecat_result", "restore_outcome"]
        )
        XCTAssertEqual(attemptIDs.count, 1)
        XCTAssertEqual(entries.last?.payload["result"], .string("not_found"))
        XCTAssertEqual(await output.callsCount(), 0)
        XCTAssertEqual(router.presentedMessages, [L10n.subscriptionRestoreNotFound])
    }
}

private extension SubscriptionLoggingTests {
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
        subscriptionAccessService: SubscriptionAccessServicing,
        appLogService: AppLogServiceProtocol
    ) -> SubscriptionInteractor {
        SubscriptionInteractor(
            presenter: presenter,
            router: router,
            currentTier: .regular,
            output: output,
            storeKitService: storeKitService,
            subscriptionAccessService: subscriptionAccessService,
            pollingIntervalNanoseconds: .zero,
            maximumPollingAttempts: 1,
            analytics: nil,
            appLogService: appLogService
        )
    }

    func waitForEntries(expected: Int, service: AppLogServiceSpy) async {
        while await service.entries().count < expected {
            await Task.yield()
        }
    }
}

@MainActor
private final class SubscriptionLoggingPresenterSpy: SubscriptionPresentationLogic {
    func presentFetchedData(_ data: SubscriptionFetchData) {}
}

@MainActor
private final class SubscriptionLoggingRouterSpy: SubscriptionRoutingLogic {
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

    func openTermsOfUse() {}

    func openPrivacyPolicy() {}
}

private actor SubscriptionLoggingOutputSpy: SubscriptionOutput {
    private var syncCallsCount = 0

    func handleSubscriptionDidSync() async {
        syncCallsCount += 1
    }

    func callsCount() -> Int {
        syncCallsCount
    }
}

private actor SubscriptionLoggingAccessServiceStub: SubscriptionAccessServicing {
    private let refreshedTierStates: [SubscriptionTierRefreshState]
    private var refreshCallsCount = 0

    init(refreshedTierStates: [SubscriptionTierRefreshState] = []) {
        self.refreshedTierStates = refreshedTierStates
    }

    func currentTierState() async -> SubscriptionTierState {
        .resolved(.regular)
    }

    func refreshCurrentTierState() async -> SubscriptionTierState {
        (await refreshCurrentTierSourceState()).tierState
    }

    func refreshCurrentTierSourceState() async -> SubscriptionTierRefreshState {
        guard !refreshedTierStates.isEmpty else {
            return .unavailable
        }

        let index = min(refreshCallsCount, refreshedTierStates.count - 1)
        refreshCallsCount += 1
        return refreshedTierStates[index]
    }
}

private final class SubscriptionLoggingServiceStub: SubscriptionServiceLogic, @unchecked Sendable {
    var currentTier: SubscriptionTier = .regular
    var loadedPlans: [SubscriptionFetchData.SubscriptionStorePlan] = []

    private let loadPlansResult: Result<[SubscriptionFetchData.SubscriptionStorePlan], Error>
    private let purchaseError: Error?
    private let restoredTier: SubscriptionTier

    init(
        loadPlansResult: Result<[SubscriptionFetchData.SubscriptionStorePlan], Error>,
        purchaseError: Error?,
        restoredTier: SubscriptionTier
    ) {
        self.loadPlansResult = loadPlansResult
        self.purchaseError = purchaseError
        self.restoredTier = restoredTier
    }

    func loadPlans() async throws -> [SubscriptionFetchData.SubscriptionStorePlan] {
        let plans = try loadPlansResult.get()
        loadedPlans = plans
        return plans
    }

    func purchase(planID: String) async throws {
        if let purchaseError {
            throw purchaseError
        }

        currentTier = .premium
    }

    func restore() async throws {
        currentTier = restoredTier
    }

    func refreshCurrentTier() async throws {}

    func manualSync() async throws {}
}
