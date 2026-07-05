import XCTest
@testable import Vylok

final class MainFlowRootInteractorTests: XCTestCase {
    func testHandlePendingRouteIfNeededRoutesHome() async {
        let pendingRouteStore = PendingVaultRouteStoreSpy(route: .home)
        let router = await MainActor.run { MainFlowRootRouterSpy() }
        let subscriptionInitializer = SubscriptionInitializerSpy()
        let sut = makeSut(
            pendingRouteStore: pendingRouteStore,
            subscriptionInitializer: subscriptionInitializer,
            router: router
        )

        await sut.handlePendingRouteIfNeeded(isViewVisible: true)

        let routeToHomeCalls = await MainActor.run { router.routeToHomeCallsCount }
        XCTAssertEqual(routeToHomeCalls, 1)
        XCTAssertEqual(pendingRouteStore.consumeCallsCount, 1)
        XCTAssertEqual(await subscriptionInitializer.initializeCallsCount(), 0)
    }

    func testHandlePendingRouteIfNeededRoutesResolvedWidgetEntry() async {
        let pendingRouteStore = PendingVaultRouteStoreSpy(route: .aiEntry)
        let resolver = WidgetEntryDestinationResolverSpy(
            destination: .manualEntry
        )
        let router = await MainActor.run { MainFlowRootRouterSpy() }
        let subscriptionInitializer = SubscriptionInitializerSpy()
        let sut = makeSut(
            pendingRouteStore: pendingRouteStore,
            subscriptionInitializer: subscriptionInitializer,
            widgetEntryDestinationResolver: resolver,
            router: router
        )

        await sut.handlePendingRouteIfNeeded(isViewVisible: true)

        let recordedDestination = await MainActor.run { router.recordedWidgetEntryDestination }
        XCTAssertEqual(recordedDestination, .manualEntry)
        XCTAssertEqual(await subscriptionInitializer.initializeCallsCount(), 1)
        XCTAssertEqual(await resolver.resolveCallsCount(), 1)
    }

    func testHandlePendingRouteIfNeededRoutesSubscription() async {
        let pendingRouteStore = PendingVaultRouteStoreSpy(route: .subscription)
        let subscriptionAccessService = SubscriptionAccessServiceSpy(
            currentTier: .premium
        )
        let router = await MainActor.run { MainFlowRootRouterSpy() }
        let subscriptionInitializer = SubscriptionInitializerSpy()
        let sut = makeSut(
            pendingRouteStore: pendingRouteStore,
            subscriptionInitializer: subscriptionInitializer,
            subscriptionAccessService: subscriptionAccessService,
            router: router
        )

        await sut.handlePendingRouteIfNeeded(isViewVisible: true)

        let recordedTier = await MainActor.run { router.recordedSubscriptionTier }
        XCTAssertEqual(recordedTier, .premium)
        XCTAssertEqual(await subscriptionInitializer.initializeCallsCount(), 1)
        XCTAssertEqual(subscriptionAccessService.currentTierStateCallsCount, 1)
    }

    func testHandlePendingRouteIfNeededDoesNothingWhenViewIsNotVisible() async {
        let pendingRouteStore = PendingVaultRouteStoreSpy(route: .aiEntry)
        let router = await MainActor.run { MainFlowRootRouterSpy() }
        let subscriptionInitializer = SubscriptionInitializerSpy()
        let sut = makeSut(
            pendingRouteStore: pendingRouteStore,
            subscriptionInitializer: subscriptionInitializer,
            router: router
        )

        await sut.handlePendingRouteIfNeeded(isViewVisible: false)

        let routeToHomeCalls = await MainActor.run { router.routeToHomeCallsCount }
        let widgetEntryCalls = await MainActor.run { router.openWidgetEntryCallsCount }
        let subscriptionCalls = await MainActor.run { router.openSubscriptionCallsCount }

        XCTAssertEqual(pendingRouteStore.consumeCallsCount, 0)
        XCTAssertEqual(routeToHomeCalls, 0)
        XCTAssertEqual(widgetEntryCalls, 0)
        XCTAssertEqual(subscriptionCalls, 0)
        XCTAssertEqual(await subscriptionInitializer.initializeCallsCount(), 0)
    }
}

private extension MainFlowRootInteractorTests {
    func makeSut(
        pendingRouteStore: PendingVylokRouteStoring = PendingVaultRouteStoreSpy(),
        subscriptionInitializer: SubscriptionInitializerLogic = SubscriptionInitializerSpy(),
        widgetEntryDestinationResolver: VylokWidgetEntryDestinationResolving = WidgetEntryDestinationResolverSpy(
            destination: .aiEntry
        ),
        subscriptionAccessService: SubscriptionAccessServicing = SubscriptionAccessServiceSpy(),
        router: MainFlowRootRoutingLogic
    ) -> MainFlowRootInteractor {
        MainFlowRootInteractor(
            context: makeContext(),
            pendingRouteStore: pendingRouteStore,
            subscriptionInitializer: subscriptionInitializer,
            widgetEntryDestinationResolver: widgetEntryDestinationResolver,
            subscriptionAccessService: subscriptionAccessService,
            widgetSubscriptionOutput: SubscriptionOutputSpy(),
            router: router
        )
    }

    func makeContext() -> MainFlowContext {
        MainFlowContext(
            store: MainFlowDomainStore(),
            observer: MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping()),
            repository: MainFlowDomainRepositorySpy(),
            analyticsIntervalRepository: AnalyticsIntervalRepository(),
            summaryPeriodProvider: MainSummaryPeriodProvider()
        )
    }
}

private actor SubscriptionInitializerSpy: SubscriptionInitializerLogic {
    private var recordedInitializeCallsCount: Int = .zero

    func initialize() async {
        recordedInitializeCallsCount += 1
    }

    func setUserId(_ id: String) async {}

    func logout() async {}

    func initializeCallsCount() -> Int {
        recordedInitializeCallsCount
    }
}

private final class PendingVaultRouteStoreSpy: PendingVylokRouteStoring, @unchecked Sendable {
    private var route: VylokRoute?
    private(set) var consumeCallsCount: Int = .zero

    init(route: VylokRoute? = nil) {
        self.route = route
    }

    func store(_ route: VylokRoute) {
        self.route = route
    }

    func consume() -> VylokRoute? {
        consumeCallsCount += 1
        defer { route = nil }
        return route
    }
}

private final class WidgetEntryDestinationResolverSpy: VylokWidgetEntryDestinationResolving, @unchecked Sendable {
    private let destination: VylokWidgetEntryDestination
    private var callsCount: Int = .zero

    init(destination: VylokWidgetEntryDestination) {
        self.destination = destination
    }

    func resolveDestination() async -> VylokWidgetEntryDestination {
        callsCount += 1
        return destination
    }

    func resolveCallsCount() async -> Int {
        callsCount
    }
}

private final class SubscriptionAccessServiceSpy: SubscriptionAccessServicing, @unchecked Sendable {
    private let tier: SubscriptionTier
    private(set) var currentTierStateCallsCount: Int = .zero

    init(currentTier: SubscriptionTier = .regular) {
        tier = currentTier
    }

    func currentTierState() async -> SubscriptionTierState {
        currentTierStateCallsCount += 1
        .resolved(tier)
    }

    func refreshCurrentTierState() async -> SubscriptionTierState {
        .resolved(tier)
    }

    func refreshCurrentTierSourceState() async -> SubscriptionTierRefreshState {
        .network(tier)
    }

    func currentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot? {
        nil
    }

    func refreshCurrentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot? {
        nil
    }

    func startMonitoring() {}
}

@MainActor
private final class MainFlowRootRouterSpy: MainFlowRootRoutingLogic, @unchecked Sendable {
    private(set) var routeToHomeCallsCount: Int = .zero
    private(set) var openWidgetEntryCallsCount: Int = .zero
    private(set) var openSubscriptionCallsCount: Int = .zero
    private(set) var recordedWidgetEntryDestination: VylokWidgetEntryDestination?
    private(set) var recordedSubscriptionTier: SubscriptionTier?

    func routeToHome() {
        routeToHomeCallsCount += 1
    }

    func openWidgetEntry(
        context: MainFlowContext,
        destination: VylokWidgetEntryDestination
    ) {
        openWidgetEntryCallsCount += 1
        recordedWidgetEntryDestination = destination
    }

    func openSubscription(
        currentTier: SubscriptionTier,
        output: SubscriptionOutput
    ) {
        openSubscriptionCallsCount += 1
        recordedSubscriptionTier = currentTier
    }
}

private final class SubscriptionOutputSpy: SubscriptionOutput, @unchecked Sendable {
    func handleSubscriptionDidSync() async {}
}

private final class MainFlowDomainRepositorySpy: MainFlowDomainRepositoryProtocol, @unchecked Sendable {
    func refreshMainFlow() async throws {}
    func refreshCategories() async throws {}
    func refreshRecentExpenses() async throws {}
    func refreshCategoryFirstPage(id: String, fromDate: Date?, toDate: Date?) async throws {}
    func refreshExpensesFirstPage() async throws {}
    func refreshLoadedPeriodDependentModules() async {}
    func handleCurrencyDidChange(_ payload: ProfileCurrencyDidChangePayload) async {}
    func loadNextCategoryPage(id: String) async throws {}
    func loadNextExpensesPage() async throws {}
    func addExpense(_ request: ExpensesCreateRequestDTO) async throws {}
    func deleteExpense(id: String) async throws {}
    func addCategory(_ request: CategoryCreateRequestDTO) async throws -> MainCategoryCardModel {
        MainCategoryCardModel(
            id: "1",
            name: request.name,
            icon: request.icon,
            color: request.color,
            amount: .zero,
            currency: "USD"
        )
    }
    func updateCategory(id: String, request: CategoryCreateRequestDTO) async throws -> MainCategoryCardModel {
        MainCategoryCardModel(
            id: id,
            name: request.name,
            icon: request.icon,
            color: request.color,
            amount: .zero,
            currency: "USD"
        )
    }
    func deleteCategory(id: String) async throws {}
    func clearSession() async {}
}
