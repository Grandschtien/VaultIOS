import XCTest
@testable import Vylok

@MainActor
final class AnalyticsInteractorTests: XCTestCase {
    func testFetchDataLoadsCurrentAnalyticsPeriod() async {
        let presenter = AnalyticsPresenterSpy()
        let dataProvider = AnalyticsDataProviderStub(
            results: [.success(makeData(monthStart: aprilStart, totalAmount: 120))]
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRouterSpy(),
            repository: AnalyticsRepositorySpy(),
            dataProvider: dataProvider,
            observer: AnalyticsObserverStub(),
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "PREMIUM")
        )

        await sut.fetchData()
        await waitForUpdates()

        let fetchCalls = await dataProvider.recordedFetchCalls()
        XCTAssertEqual(fetchCalls, [aprilCurrentPeriod])
        XCTAssertEqual(presenter.presentedData.first?.loadingState, .loading)
        XCTAssertEqual(presenter.presentedData.last?.loadingState, .loaded)
        XCTAssertEqual(presenter.presentedData.last?.data?.totalAmount, 120)
    }

    func testFetchDataUsesAnalyticsCapabilityInsteadOfTier() async {
        let presenter = AnalyticsPresenterSpy()
        let dataProvider = AnalyticsDataProviderStub(
            results: [.success(makeData(monthStart: aprilStart, totalAmount: 120))]
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRouterSpy(),
            repository: AnalyticsRepositorySpy(),
            dataProvider: dataProvider,
            observer: AnalyticsObserverStub(),
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: SubscriptionAccessServiceStub(
                currentTier: "REGULAR",
                currentSnapshot: .init(
                    tier: .regular,
                    status: .active,
                    paidAccessUntil: nil,
                    capabilities: [.analytics],
                    aiRequestsLimit: 0,
                    aiRequestsRemaining: 0,
                    statusVersion: 42
                )
            )
        )

        await sut.fetchData()
        await waitForUpdates()

        let fetchCalls = await dataProvider.recordedFetchCalls()
        XCTAssertEqual(fetchCalls, [aprilCurrentPeriod])
        XCTAssertEqual(presenter.presentedData.last?.isLocked, false)
        XCTAssertEqual(presenter.presentedData.last?.loadingState, .loaded)
    }
}

extension AnalyticsInteractorTests {
    func testFetchDataWhenTierStateIsUnavailableShowsErrorInsteadOfLockedState() async {
        let presenter = AnalyticsPresenterSpy()
        let observer = AnalyticsObserverStub()
        let dataProvider = AnalyticsDataProviderStub(results: [])
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRouterSpy(),
            repository: AnalyticsRepositorySpy(),
            dataProvider: dataProvider,
            observer: observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTierState: .unavailable)
        )

        await sut.fetchData()
        let recordedFetchCalls = await dataProvider.recordedFetchCalls()

        XCTAssertEqual(recordedFetchCalls, [])
        XCTAssertEqual(observer.subscribeOverviewCallsCount, 0)
        XCTAssertEqual(presenter.presentedData.last?.isLocked, false)

        guard case .failed = presenter.presentedData.last?.loadingState else {
            return XCTFail("Expected Analytics to show an error state when tier resolution is unavailable")
        }
    }
}

extension AnalyticsInteractorTests {
    func testHandleTapRetryKeepsLoadedDataWhenRefreshFails() async {
        let presenter = AnalyticsPresenterSpy()
        let dataProvider = AnalyticsDataProviderStub(
            results: [
                .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                .failure(StubError.any)
            ]
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRouterSpy(),
            repository: AnalyticsRepositorySpy(),
            dataProvider: dataProvider,
            observer: AnalyticsObserverStub(),
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "PREMIUM")
        )

        await sut.fetchData()
        await waitForUpdates()

        await sut.handleTapRetry()
        await waitForUpdates()

        let fetchCalls = await dataProvider.recordedFetchCalls()
        XCTAssertEqual(fetchCalls, [aprilCurrentPeriod, aprilCurrentPeriod])
        XCTAssertEqual(presenter.presentedData.last?.loadingState, .loaded)
        XCTAssertEqual(presenter.presentedData.last?.data?.totalAmount, 120)
    }
}

extension AnalyticsInteractorTests {
    func testHandleDidConfirmCategoryPeriodUpdatesLocalPeriodAndLoadsConfirmedRange() async {
        let presenter = AnalyticsPresenterSpy()
        let dataProvider = AnalyticsDataProviderStub(
            results: [
                .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                .success(makeData(monthStart: marchStart, totalAmount: 80))
            ]
        )
        let repository = AnalyticsRepositorySpy()
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRouterSpy(),
            repository: repository,
            dataProvider: dataProvider,
            observer: AnalyticsObserverStub(),
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "PREMIUM")
        )

        await sut.fetchData()
        await waitForUpdates()
        await sut.handleDidConfirmCategoryPeriod(
            fromDate: marchCustomPeriod.from,
            to: marchCustomPeriod.to
        )
        await waitForUpdates()

        let fetchCalls = await dataProvider.recordedFetchCalls()
        let refreshMainFlowCalls = await repository.refreshMainFlowCalls()
        let refreshLoadedModulesCalls = await repository.refreshLoadedPeriodDependentModulesCalls()
        XCTAssertEqual(fetchCalls, [aprilCurrentPeriod, marchCustomPeriod])
        XCTAssertEqual(refreshMainFlowCalls, 0)
        XCTAssertEqual(refreshLoadedModulesCalls, 0)
        XCTAssertEqual(presenter.presentedData.last?.selectedPeriod, marchCustomPeriod)
        XCTAssertNil(presenter.presentedData.last?.selectedPreset)
        XCTAssertEqual(presenter.presentedData.last?.data?.monthStart, marchStart)
    }
}

extension AnalyticsInteractorTests {
    func testHandleDidConfirmCategoryPeriodShowsErrorWhenNewPeriodLoadFails() async {
        let presenter = AnalyticsPresenterSpy()
        let dataProvider = AnalyticsDataProviderStub(
            results: [
                .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                .failure(StubError.any)
            ]
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRouterSpy(),
            repository: AnalyticsRepositorySpy(),
            dataProvider: dataProvider,
            observer: AnalyticsObserverStub(),
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "PREMIUM")
        )

        await sut.fetchData()
        await waitForUpdates()
        await sut.handleDidConfirmCategoryPeriod(
            fromDate: marchCustomPeriod.from,
            to: marchCustomPeriod.to
        )
        await waitForUpdates()

        let fetchCalls = await dataProvider.recordedFetchCalls()
        XCTAssertEqual(fetchCalls, [aprilCurrentPeriod, marchCustomPeriod])
        XCTAssertEqual(presenter.presentedData.last?.selectedPeriod, marchCustomPeriod)
        XCTAssertEqual(presenter.presentedData.last?.loadingState, .failed(.undelinedError(description: StubError.any.localizedDescription)))
        XCTAssertNil(presenter.presentedData.last?.data)
    }
}

extension AnalyticsInteractorTests {
    func testHandleTapCategoryRoutesToCategoryScreen() async {
        let router = AnalyticsRouterSpy()
        let sut = AnalyticsInteractor(
            presenter: AnalyticsPresenterSpy(),
            router: router,
            repository: AnalyticsRepositorySpy(),
            dataProvider: AnalyticsDataProviderStub(results: []),
            observer: AnalyticsObserverStub(),
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "PREMIUM")
        )

        await sut.fetchData()
        await sut.handleTapCategory(id: "food", name: "Food")

        XCTAssertEqual(router.openCategoryCalls.count, 1)
        XCTAssertEqual(router.openCategoryCalls.first?.0, "food")
        XCTAssertEqual(router.openCategoryCalls.first?.1, "Food")
        XCTAssertEqual(router.openCategoryCalls.first?.2, aprilCurrentPeriod)
    }
}

extension AnalyticsInteractorTests {
    func testHandleTapMonthFilterRoutesWithCurrentLocalPeriod() async {
        let router = AnalyticsRouterSpy()
        let sut = AnalyticsInteractor(
            presenter: AnalyticsPresenterSpy(),
            router: router,
            repository: AnalyticsRepositorySpy(),
            dataProvider: AnalyticsDataProviderStub(
                results: [
                    .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                    .success(makeData(monthStart: marchStart, totalAmount: 80))
                ]
            ),
            observer: AnalyticsObserverStub(),
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "PREMIUM")
        )

        await sut.fetchData()
        await waitForUpdates()
        await sut.handleDidConfirmCategoryPeriod(
            fromDate: marchCustomPeriod.from,
            to: marchCustomPeriod.to
        )
        await waitForUpdates()
        await sut.handleTapMonthFilter()

        XCTAssertEqual(router.openPeriodPickerCalls, [marchCustomPeriod])
    }

    func testHandleTapMonthFilterWithoutCustomDateAccessOpensSubscription() async {
        let router = AnalyticsRouterSpy()
        let sut = AnalyticsInteractor(
            presenter: AnalyticsPresenterSpy(),
            router: router,
            repository: AnalyticsRepositorySpy(),
            dataProvider: AnalyticsDataProviderStub(results: []),
            observer: AnalyticsObserverStub(),
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: SubscriptionAccessServiceStub(
                currentTier: "PREMIUM",
                currentSnapshot: .init(
                    tier: .premium,
                    status: .active,
                    paidAccessUntil: nil,
                    capabilities: [.analytics],
                    aiRequestsLimit: 300,
                    aiRequestsRemaining: 300,
                    statusVersion: 42
                )
            )
        )

        await sut.fetchData()
        await sut.handleTapMonthFilter()

        XCTAssertTrue(router.openPeriodPickerCalls.isEmpty)
        XCTAssertEqual(router.lastOpenedSubscriptionTier, .premium)
    }
}

extension AnalyticsInteractorTests {
    func testHandleSelectPresetDoesNotRefetchSubscriptionOrAnalyticsDataWithinSameDay() async {
        let presenter = AnalyticsPresenterSpy()
        let dataProvider = AnalyticsDataProviderStub(
            results: [.success(makeData(monthStart: aprilStart, totalAmount: 120))]
        )
        let subscriptionAccessService = SubscriptionAccessServiceStub(currentTier: "PREMIUM")
        var currentDate = makeDate(
            year: 2026,
            month: 4,
            day: 6,
            hour: 10,
            minute: 0,
            second: 0
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRouterSpy(),
            repository: AnalyticsRepositorySpy(),
            dataProvider: dataProvider,
            observer: AnalyticsObserverStub(),
            periodResolver: AnalyticsPeriodResolver(
                calendar: calendar,
                now: { currentDate }
            ),
            subscriptionAccessService: subscriptionAccessService
        )

        await sut.fetchData()
        await waitForUpdates()
        let fetchCallsCountBeforeSwitch = await dataProvider.recordedFetchCalls().count

        currentDate = makeDate(
            year: 2026,
            month: 4,
            day: 6,
            hour: 10,
            minute: 1,
            second: 30
        )
        await sut.handleSelectPreset(.week)
        await waitForUpdates()

        let fetchCallsCountAfterSwitch = await dataProvider.recordedFetchCalls().count
        let currentSnapshotCallsCount = await subscriptionAccessService.currentSubscriptionSnapshotCallsCount()
        XCTAssertEqual(fetchCallsCountAfterSwitch, fetchCallsCountBeforeSwitch)
        XCTAssertEqual(currentSnapshotCallsCount, 1)
        XCTAssertEqual(presenter.presentedData.last?.selectedPreset, .week)
    }

    func testObserverInvalidationRefreshesCurrentLocalPeriod() async {
        let presenter = AnalyticsPresenterSpy()
        let dataProvider = AnalyticsDataProviderStub(
            results: [
                .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                .success(makeData(monthStart: marchStart, totalAmount: 80)),
                .success(makeData(monthStart: marchStart, totalAmount: 140))
            ]
        )
        let observer = AnalyticsObserverStub()
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRouterSpy(),
            repository: AnalyticsRepositorySpy(),
            dataProvider: dataProvider,
            observer: observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "PREMIUM")
        )

        await sut.fetchData()
        await waitForUpdates()
        await sut.handleDidConfirmCategoryPeriod(
            fromDate: marchCustomPeriod.from,
            to: marchCustomPeriod.to
        )
        await waitForUpdates()
        observer.publishOverview()
        await waitForUpdates()

        let fetchCalls = await dataProvider.recordedFetchCalls()
        XCTAssertEqual(
            fetchCalls,
            [aprilCurrentPeriod, marchCustomPeriod, marchCustomPeriod]
        )
        XCTAssertEqual(presenter.presentedData.last?.data?.totalAmount, 140)
        XCTAssertEqual(presenter.presentedData.last?.selectedPeriod, marchCustomPeriod)
    }

    func testSubscriptionAccessDowngradeLocksScreenAndStopsOverviewRefresh() async {
        let presenter = AnalyticsPresenterSpy()
        let dataProvider = AnalyticsDataProviderStub(
            results: [.success(makeData(monthStart: aprilStart, totalAmount: 120))]
        )
        let observer = AnalyticsObserverStub()
        let notificationCenter = NotificationCenter()
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRouterSpy(),
            repository: AnalyticsRepositorySpy(),
            dataProvider: dataProvider,
            observer: observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "PREMIUM"),
            notificationCenter: notificationCenter
        )

        await sut.fetchData()
        await waitForUpdates()
        let fetchCallsBeforeDowngrade = await dataProvider.recordedFetchCalls()
        let fetchCallsCountBeforeDowngrade = fetchCallsBeforeDowngrade.count

        notificationCenter.post(
            name: .subscriptionAccessDidChange,
            object: makeSubscriptionSnapshot(tier: .regular)
        )
        await waitForUpdates()
        observer.publishOverview()
        await waitForUpdates()

        let fetchCallsAfterDowngrade = await dataProvider.recordedFetchCalls()
        let fetchCallsCountAfterDowngrade = fetchCallsAfterDowngrade.count
        XCTAssertEqual(fetchCallsCountAfterDowngrade, fetchCallsCountBeforeDowngrade)
        XCTAssertEqual(presenter.presentedData.last?.isLocked, true)
        XCTAssertNil(presenter.presentedData.last?.data)
    }

    func testUsageOnlyNotificationDoesNotLockScreenWhenSemanticStatusMatches() async {
        let presenter = AnalyticsPresenterSpy()
        let dataProvider = AnalyticsDataProviderStub(
            results: [.success(makeData(monthStart: aprilStart, totalAmount: 120))]
        )
        let notificationCenter = NotificationCenter()
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRouterSpy(),
            repository: AnalyticsRepositorySpy(),
            dataProvider: dataProvider,
            observer: AnalyticsObserverStub(),
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "PREMIUM"),
            notificationCenter: notificationCenter
        )

        await sut.fetchData()
        await waitForUpdates()

        notificationCenter.post(
            name: .subscriptionAccessDidChange,
            object: makeSubscriptionSnapshot(tier: .regular, aiRequestsRemaining: 271),
            userInfo: [
                SubscriptionAccessDidChangeNotificationUserInfoKey.previousSnapshot:
                    makeSubscriptionSnapshot(tier: .regular, aiRequestsRemaining: 272)
            ]
        )
        await waitForUpdates()

        XCTAssertEqual(presenter.presentedData.last?.isLocked, false)
        XCTAssertEqual(await dataProvider.recordedFetchCalls(), [aprilCurrentPeriod])
    }

    func testHandleSubscriptionDidSyncKeepsSelectedLocalPeriodAndLoadsAnalytics() async {
        let presenter = AnalyticsPresenterSpy()
        let dataProvider = AnalyticsDataProviderStub(
            results: [
                .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                .success(makeData(monthStart: marchStart, totalAmount: 90)),
                .success(makeData(monthStart: marchStart, totalAmount: 130))
            ]
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRouterSpy(),
            repository: AnalyticsRepositorySpy(),
            dataProvider: dataProvider,
            observer: AnalyticsObserverStub(),
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "PREMIUM", refreshedTier: "PREMIUM")
        )

        await sut.fetchData()
        await waitForUpdates()
        await sut.handleDidConfirmCategoryPeriod(
            fromDate: marchCustomPeriod.from,
            to: marchCustomPeriod.to
        )
        await waitForUpdates()
        await sut.handleSubscriptionDidSync()
        await waitForUpdates()

        let fetchCalls = await dataProvider.recordedFetchCalls()

        XCTAssertEqual(fetchCalls, [aprilCurrentPeriod, marchCustomPeriod, marchCustomPeriod])
        XCTAssertEqual(presenter.presentedData.last?.selectedPeriod, marchCustomPeriod)
        XCTAssertEqual(presenter.presentedData.last?.data?.totalAmount, 130)
    }

    func testFetchDataWithRegularTierShowsLockedStateWithoutLoadingData() async {
        let presenter = AnalyticsPresenterSpy()
        let observer = AnalyticsObserverStub()
        let dataProvider = AnalyticsDataProviderStub(results: [])
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRouterSpy(),
            repository: AnalyticsRepositorySpy(),
            dataProvider: dataProvider,
            observer: observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "REGULAR")
        )

        await sut.fetchData()
        let recordedFetchCalls = await dataProvider.recordedFetchCalls()

        XCTAssertEqual(recordedFetchCalls, [])
        XCTAssertEqual(observer.subscribeOverviewCallsCount, 0)
        XCTAssertEqual(presenter.presentedData.last?.isLocked, true)
    }

    func testHandleTapSubscribeOpensSubscription() async {
        let router = AnalyticsRouterSpy()
        let sut = AnalyticsInteractor(
            presenter: AnalyticsPresenterSpy(),
            router: router,
            repository: AnalyticsRepositorySpy(),
            dataProvider: AnalyticsDataProviderStub(results: []),
            observer: AnalyticsObserverStub(),
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "REGULAR")
        )

        await sut.fetchData()
        await sut.handleTapSubscribe()

        XCTAssertEqual(router.lastOpenedSubscriptionTier, .regular)
    }

    func testHandleSubscriptionDidSyncRefreshesTierAndLoadsAnalyticsWhenUnlocked() async {
        let presenter = AnalyticsPresenterSpy()
        let dataProvider = AnalyticsDataProviderStub(
            results: [.success(makeData(monthStart: aprilStart, totalAmount: 220))]
        )
        let subscriptionAccessService = SubscriptionAccessServiceStub(
            currentTier: "REGULAR",
            refreshedTier: "PREMIUM"
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRouterSpy(),
            repository: AnalyticsRepositorySpy(),
            dataProvider: dataProvider,
            observer: AnalyticsObserverStub(),
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: subscriptionAccessService
        )

        await sut.fetchData()
        await sut.handleSubscriptionDidSync()
        await waitForUpdates()
        let refreshCallsCount = await subscriptionAccessService.refreshCallsCount()
        let recordedFetchCalls = await dataProvider.recordedFetchCalls()

        XCTAssertEqual(refreshCallsCount, 1)
        XCTAssertEqual(recordedFetchCalls, [aprilCurrentPeriod])
        XCTAssertEqual(presenter.presentedData.last?.isLocked, false)
        XCTAssertEqual(presenter.presentedData.last?.data?.totalAmount, 220)
    }
}

private extension AnalyticsInteractorTests {
    enum StubError: LocalizedError {
        case any

        var errorDescription: String? {
            "Any error"
        }
    }

    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    var aprilStart: Date {
        makeDate(year: 2026, month: 4, day: 1)
    }

    var aprilCurrentPeriod: MainSummaryPeriod {
        .init(
            from: aprilStart,
            to: makeDate(year: 2026, month: 4, day: 6)
        )
    }

    var aprilCustomPeriod: MainSummaryPeriod {
        .init(
            from: makeDate(year: 2026, month: 4, day: 2),
            to: makeDate(year: 2026, month: 4, day: 6)
        )
    }

    var marchStart: Date {
        makeDate(year: 2026, month: 3, day: 1)
    }

    var marchCustomPeriod: MainSummaryPeriod {
        .init(
            from: makeDate(year: 2026, month: 3, day: 18),
            to: marchEnd
        )
    }

    var marchEnd: Date {
        calendar.dateInterval(of: .month, for: marchStart)?.end.addingTimeInterval(-1) ?? .distantPast
    }

    func makePeriodResolver(now: Date? = nil) -> AnalyticsPeriodResolving {
        let currentDate = now ?? aprilCurrentPeriod.to
        return AnalyticsPeriodResolver(
            calendar: calendar,
            now: { currentDate }
        )
    }

    func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0
    ) -> Date {
        calendar.date(
            from: DateComponents(
                timeZone: calendar.timeZone,
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                second: second
            )
        ) ?? .distantPast
    }

    func makeData(
        monthStart: Date,
        totalAmount: Double
    ) -> AnalyticsDataModel {
        AnalyticsDataModel(
            monthStart: monthStart,
            totalAmount: totalAmount,
            currency: "USD",
            categories: [
                .init(
                    id: "food",
                    name: "Food",
                    icon: "🍔",
                    colorValue: "light_green",
                    amount: totalAmount,
                    currency: "USD",
                    share: 1,
                    isInteractive: true
                )
            ]
        )
    }

    func makeSubscriptionSnapshot(
        tier: SubscriptionTier,
        aiRequestsRemaining: Int? = nil
    ) -> SubscriptionAccessSnapshot {
        let capabilities: [SubscriptionCapability] = switch tier {
        case .premium:
            [.analytics, .customDateRange, .aiInput]
        case .regular:
            []
        }

        return SubscriptionAccessSnapshot(
            tier: tier,
            status: .active,
            paidAccessUntil: nil,
            capabilities: capabilities,
            aiRequestsLimit: capabilities.isEmpty ? 0 : 300,
            aiRequestsRemaining: aiRequestsRemaining ?? (capabilities.isEmpty ? 0 : 300),
            statusVersion: 42
        )
    }

    func waitForUpdates() async {
        await Task.yield()
        await Task.yield()
        await Task.yield()
    }
}

@MainActor
private final class AnalyticsPresenterSpy: AnalyticsPresentationLogic {
    private(set) var presentedData: [AnalyticsFetchData] = []

    func presentFetchedData(_ data: AnalyticsFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class AnalyticsRouterSpy: AnalyticsRoutingLogic {
    private(set) var openCategoryCalls: [(String, String, MainSummaryPeriod)] = []
    private(set) var openPeriodPickerCalls: [MainSummaryPeriod] = []
    private(set) var lastOpenedSubscriptionTier: SubscriptionTier?

    func openCategory(id: String, name: String, period: MainSummaryPeriod) {
        openCategoryCalls.append((id, name, period))
    }

    func openSubscription(
        currentTier: SubscriptionTier,
        output: SubscriptionOutput
    ) {
        lastOpenedSubscriptionTier = currentTier
    }

    func openPeriodPicker(
        selectedFromDate: Date,
        selectedToDate: Date,
        output: CategoryPeriodPickerOutput
    ) {
        openPeriodPickerCalls.append(
            .init(
                from: selectedFromDate,
                to: selectedToDate
            )
        )
    }
}

private final class AnalyticsObserverStub: MainFlowDomainObserverProtocol, @unchecked Sendable {
    private var continuation: AsyncStream<MainFlowOverviewSnapshot>.Continuation?
    private(set) var subscribeOverviewCallsCount = 0

    func subscribeOverview() -> AsyncStream<MainFlowOverviewSnapshot> {
        subscribeOverviewCallsCount += 1
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.continuation = continuation
            continuation.yield(.init())
        }
    }

    func subscribeCategories() -> AsyncStream<MainFlowCategoriesSnapshot> {
        AsyncStream { $0.finish() }
    }

    func subscribeCategory(id: String) -> AsyncStream<MainFlowCategorySnapshot> {
        AsyncStream { $0.finish() }
    }

    func subscribeExpensesList() -> AsyncStream<MainFlowExpensesListSnapshot> {
        AsyncStream { $0.finish() }
    }

    func currentOverviewSnapshot() -> MainFlowOverviewSnapshot {
        .init()
    }

    func currentCategoriesSnapshot() -> MainFlowCategoriesSnapshot {
        .init()
    }

    func currentCategorySnapshot(id: String) -> MainFlowCategorySnapshot {
        .init(categoryID: id)
    }

    func currentExpensesListSnapshot() -> MainFlowExpensesListSnapshot {
        .init()
    }

    func publishAll(from store: MainFlowDomainStoreProtocol) {}

    func finishAll() {
        continuation?.finish()
    }

    func publishOverview() {
        continuation?.yield(.init())
    }
}

private actor AnalyticsRepositorySpy: MainFlowDomainRepositoryProtocol {
    private var refreshMainFlowCallCount = 0
    private var refreshLoadedPeriodDependentModulesCallCount = 0

    func refreshMainFlow() async throws {
        refreshMainFlowCallCount += 1
    }

    func refreshCategories() async throws {}
    func refreshRecentExpenses() async throws {}
    func refreshCategoryFirstPage(id: String, fromDate: Date?, toDate: Date?) async throws {}
    func refreshExpensesFirstPage() async throws {}
    func refreshLoadedPeriodDependentModules() async {
        refreshLoadedPeriodDependentModulesCallCount += 1
    }
    func handleCurrencyDidChange(_ payload: ProfileCurrencyDidChangePayload) async {}
    func loadNextCategoryPage(id: String) async throws {}
    func loadNextExpensesPage() async throws {}
    func addExpense(_ request: ExpensesCreateRequestDTO) async throws {}
    func deleteExpense(id: String) async throws {}
    func addCategory(_ request: CategoryCreateRequestDTO) async throws -> MainCategoryCardModel { .init(id: "", name: "", icon: "", color: "", amount: 0, currency: "USD") }
    func updateCategory(id: String, request: CategoryCreateRequestDTO) async throws -> MainCategoryCardModel { .init(id: id, name: "", icon: "", color: "", amount: 0, currency: "USD") }
    func deleteCategory(id: String) async throws {}
    func clearSession() async {}

    func refreshMainFlowCalls() -> Int {
        refreshMainFlowCallCount
    }

    func refreshLoadedPeriodDependentModulesCalls() -> Int {
        refreshLoadedPeriodDependentModulesCallCount
    }
}

private actor AnalyticsDataProviderStub: AnalyticsDataProviding {
    private let results: [Result<AnalyticsDataModel, Error>]
    private var nextIndex = 0
    private(set) var fetchCalls: [MainSummaryPeriod] = []

    init(results: [Result<AnalyticsDataModel, Error>]) {
        self.results = results
    }

    func fetchData(for period: MainSummaryPeriod) async throws -> AnalyticsDataModel {
        fetchCalls.append(period)
        guard results.isEmpty == false else {
            return AnalyticsDataModel(
                monthStart: period.from,
                totalAmount: 0,
                currency: "USD",
                categories: []
            )
        }

        let index = min(nextIndex, max(results.count - 1, 0))
        nextIndex += 1
        return try results[index].get()
    }

    func recordedFetchCalls() -> [MainSummaryPeriod] {
        fetchCalls
    }
}

private final class MainSummaryPeriodServiceStub: MainSummaryPeriodServicing, @unchecked Sendable {
    private var period: MainSummaryPeriod
    private let defaultPeriod: MainSummaryPeriod
    private(set) var resetCallsCount = 0

    init(
        period: MainSummaryPeriod,
        defaultPeriod: MainSummaryPeriod? = nil
    ) {
        self.period = period
        self.defaultPeriod = defaultPeriod ?? period
    }

    func currentMonthPeriod() -> MainSummaryPeriod {
        period
    }

    func updatePeriod(from: Date, to: Date) {
        period = .init(
            from: from,
            to: to
        )
    }

    func resetToCurrentMonth() {
        resetCallsCount += 1
        period = defaultPeriod
    }
}

private actor SubscriptionAccessServiceStub: SubscriptionAccessServicing {
    private let currentTierStateValue: SubscriptionTierState
    private let refreshedTierStateValue: SubscriptionTierState
    private let currentSnapshotValue: SubscriptionAccessSnapshot?
    private let refreshedSnapshotValue: SubscriptionAccessSnapshot?
    private var refreshCalls = 0
    private var currentSubscriptionSnapshotCalls = 0

    init(
        currentTier: String = "REGULAR",
        refreshedTier: String? = nil,
        currentTierState: SubscriptionTierState? = nil,
        refreshedTierState: SubscriptionTierState? = nil,
        currentSnapshot: SubscriptionAccessSnapshot? = nil,
        refreshedSnapshot: SubscriptionAccessSnapshot? = nil
    ) {
        currentTierStateValue = currentTierState ?? .resolved(Self.makeTier(from: currentTier))
        refreshedTierStateValue = refreshedTierState ?? .resolved(
            Self.makeTier(from: refreshedTier ?? currentTier)
        )
        currentSnapshotValue = currentSnapshot ?? Self.makeSnapshot(from: currentTierStateValue)
        refreshedSnapshotValue = refreshedSnapshot ?? Self.makeSnapshot(from: refreshedTierStateValue)
    }

    func currentTierState() async -> SubscriptionTierState {
        currentTierStateValue
    }

    func refreshCurrentTierState() async -> SubscriptionTierState {
        refreshCalls += 1
        return refreshedTierStateValue
    }

    func refreshCurrentTierSourceState() async -> SubscriptionTierRefreshState {
        refreshCalls += 1

        switch refreshedTierStateValue {
        case .resolved(let tier):
            return .network(tier)
        case .unavailable:
            return .unavailable
        }
    }

    func currentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot? {
        currentSubscriptionSnapshotCalls += 1
        currentSnapshotValue
    }

    func refreshCurrentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot? {
        refreshCalls += 1
        return refreshedSnapshotValue
    }

    func currentSubscriptionSnapshotCallsCount() -> Int {
        currentSubscriptionSnapshotCalls
    }

    func refreshCallsCount() -> Int {
        refreshCalls
    }

    nonisolated private static func makeSnapshot(
        from tierState: SubscriptionTierState
    ) -> SubscriptionAccessSnapshot? {
        switch tierState {
        case .unavailable:
            nil
        case .resolved(let tier):
            let capabilities: [SubscriptionCapability] = switch tier {
            case .premium:
                [SubscriptionCapability.analytics, .customDateRange, .aiInput]
            case .regular:
                []
            }

            return SubscriptionAccessSnapshot(
                tier: tier,
                status: .active,
                paidAccessUntil: nil,
                capabilities: capabilities,
                aiRequestsLimit: capabilities.isEmpty ? 0 : 300,
                aiRequestsRemaining: capabilities.isEmpty ? 0 : 300,
                statusVersion: 42
            )
        }
    }

    nonisolated private static func makeTier(from rawTier: String) -> SubscriptionTier {
        rawTier == "REGULAR" ? .regular : .premium
    }
}
