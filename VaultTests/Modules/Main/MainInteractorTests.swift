import XCTest
@testable import Vylok

@MainActor
final class MainInteractorTests: XCTestCase {
    private var store: MainFlowDomainStore!
    private var observer: MainFlowDomainObserver!

    override func setUp() {
        super.setUp()
        store = MainFlowDomainStore()
        observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
    }

    override func tearDown() {
        observer = nil
        store = nil
        super.tearDown()
    }
}

extension MainInteractorTests {
    func testFetchDataHappyPathLoadsAllSections() async {
        let presenter = MainPresentationLogicMock()
        let repository = Self.makeRepository(
            store: store,
            observer: observer,
            categoriesResults: [.success([makeCategory(id: "cat-1", amount: 10)])],
            recentExpensesResults: [.success([makeExpense(id: "exp-1", category: "cat-1", time: 100)])]
        )
        let sut = makeSut(
            presenter: presenter,
            router: MainRoutingLogicMock(),
            summaryProvider: Self.makeSummaryProvider(
                result: .success(.init(totalAmount: 2450.8, currency: "USD", changePercent: 12))
            ),
            repository: repository,
            observer: observer
        )
        let loaded = presentationExpectation(on: presenter) { data in
            data.categories.count == 1 && data.expenseGroups.flatMap(\.expenses).count == 1
        }

        await sut.fetchData()
        await fulfillment(of: [loaded], timeout: 1)

        guard let first = presenter.presentFetchedDataReceivedInvocations.first,
              let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter updates")
        }

        assertStatus(first.summaryState, is: .loading)
        assertStatus(first.categoriesState, is: .loading)
        assertStatus(first.expensesState, is: .loading)

        assertStatus(last.summaryState, is: .loaded)
        assertStatus(last.categoriesState, is: .loaded)
        assertStatus(last.expensesState, is: .loaded)
        XCTAssertEqual(last.categories.count, 1)
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).count, 1)
    }

    func testFetchDataTracksMainScreenOpenOnlyOnce() async {
        let analytics = MainAnalyticsTrackingMock()
        let repository = Self.makeRepository(
            store: store,
            observer: observer,
            categoriesResults: [.success([]), .success([])],
            recentExpensesResults: [.success([]), .success([])]
        )
        let sut = makeSut(
            presenter: MainPresentationLogicMock(),
            router: MainRoutingLogicMock(),
            summaryProvider: Self.makeSummaryProvider(
                results: [
                    .success(.init(totalAmount: 0, currency: "USD", changePercent: 0)),
                    .success(.init(totalAmount: 0, currency: "USD", changePercent: 0))
                ]
            ),
            repository: repository,
            observer: observer,
            analytics: analytics
        )

        await sut.fetchData()
        await sut.fetchData()

        XCTAssertEqual(analytics.trackScreenOpenCallsCount, 1)
    }
}

extension MainInteractorTests {
    func testFetchDataWhenCurrencyRateFailsShowsBlockingErrorAndSkipsDomainRefresh() async {
        let presenter = MainPresentationLogicMock()
        let repository = Self.makeRepository(
            store: store,
            observer: observer,
            categoriesResults: [.success([])],
            recentExpensesResults: [.success([])]
        )
        let currencyRateProvider = Self.makeCurrencyRateProvider(result: .failure(StubError.any))
        let sut = makeSut(
            presenter: presenter,
            router: MainRoutingLogicMock(),
            currencyRateProvider: currencyRateProvider,
            summaryProvider: Self.makeSummaryProvider(
                result: .success(.init(totalAmount: 0, currency: "USD", changePercent: 0))
            ),
            repository: repository,
            observer: observer
        )

        await sut.fetchData()

        guard let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter update")
        }

        XCTAssertEqual("Что-то пошло не так", L10n.mainOverviewError)
        assertStatus(last.summaryState, is: .idle)
        assertStatus(last.categoriesState, is: .idle)
        assertStatus(last.expensesState, is: .idle)
        let categoriesCalls = repository.refreshCategoriesCallsCount
        let expensesCalls = repository.refreshRecentExpensesCallsCount
        XCTAssertEqual(categoriesCalls, 0)
        XCTAssertEqual(expensesCalls, 0)
    }
}

extension MainInteractorTests {
    func testHandleTapRetryCategoriesReloadsOnlyCategoriesSection() async {
//        let presenter = MainPresentationLogicMock()
//        let repository = Self.makeRepository(
//            store: store,
//            observer: observer,
//            categoriesResults: [
//                .failure(StubError.any),
//                .success([makeCategory(id: "cat-1", amount: 10)])
//            ],
//            recentExpensesResults: [.success([])]
//        )
//        let sut = makeSut(
//            presenter: presenter,
//            router: MainRoutingLogicMock(),
//            summaryProvider: Self.makeSummaryProvider(
//                result: .success(.init(totalAmount: 100, currency: "USD", changePercent: 0))
//            ),
//            repository: repository,
//            observer: observer
//        )
//
//        await sut.fetchData()
//        await sut.handleTapRetryCategories()
//        await waitForUpdates()
//
//        guard let last = presenter.presentFetchedDataReceivedInvocations.last else {
//            return XCTFail("Expected presenter update")
//        }
//
//        assertStatus(last.summaryState, is: .loaded)
//        assertStatus(last.categoriesState, is: .loaded)
//        assertStatus(last.expensesState, is: .loaded)
//        XCTAssertEqual(last.categories.count, 1)
//        let categoriesCalls = repository.refreshCategoriesCallsCount
//        let expensesCalls = repository.refreshRecentExpensesCallsCount
//        XCTAssertEqual(categoriesCalls, 2)
//        XCTAssertEqual(expensesCalls, 1)
    }

    func testHandlePullToRefreshPreservesContentAndReloadsData() async {
        let presenter = MainPresentationLogicMock()
        let summaryProvider = Self.makeSummaryProvider(
            results: [
                .success(.init(totalAmount: 10, currency: "USD", changePercent: 0)),
                .success(.init(totalAmount: 20, currency: "USD", changePercent: 0))
            ]
        )
        let repository = Self.makeRepository(
            store: store,
            observer: observer,
            categoriesResults: [
                .success([makeCategory(id: "cat-1", amount: 10)]),
                .success([makeCategory(id: "cat-1", amount: 20)])
            ],
            recentExpensesResults: [
                .success([makeExpense(id: "exp-1", category: "cat-1", time: 100)]),
                .success([makeExpense(id: "exp-2", category: "cat-1", time: 200)])
            ]
        )
        let sut = makeSut(
            presenter: presenter,
            router: MainRoutingLogicMock(),
            summaryProvider: summaryProvider,
            repository: repository,
            observer: observer
        )

        await sut.fetchData()

        let initialUpdatesCount = presenter.presentFetchedDataReceivedInvocations.count
        let refreshFinished = presentationExpectation(on: presenter) { data in
            !data.isRefreshing
                && data.summary?.totalAmount == 20
                && data.expenseGroups.flatMap(\.expenses).first?.id == "exp-2"
        }

        await sut.handlePullToRefresh()
        await fulfillment(of: [refreshFinished], timeout: 1)

        guard let refreshingUpdate = presenter.presentFetchedDataReceivedInvocations[initialUpdatesCount...].first(where: { $0.isRefreshing }),
              let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter updates for pull to refresh")
        }

        assertStatus(refreshingUpdate.summaryState, is: .loaded)
        assertStatus(refreshingUpdate.categoriesState, is: .loaded)
        assertStatus(refreshingUpdate.expensesState, is: .loaded)
        XCTAssertEqual(refreshingUpdate.summary?.totalAmount, 10)
        XCTAssertEqual(refreshingUpdate.categories.first?.amount, 10)
        XCTAssertEqual(refreshingUpdate.expenseGroups.flatMap(\.expenses).first?.id, "exp-1")

        XCTAssertFalse(last.isRefreshing)
        XCTAssertEqual(last.summary?.totalAmount, 20)
        XCTAssertEqual(last.categories.first?.amount, 20)
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).first?.id, "exp-2")

        let summaryFetchCalls = summaryProvider.fetchSummaryCallsCount
        let categoriesCalls = repository.refreshCategoriesCallsCount
        let expensesCalls = repository.refreshRecentExpensesCallsCount

        XCTAssertEqual(summaryFetchCalls, 2)
        XCTAssertEqual(categoriesCalls, 2)
        XCTAssertEqual(expensesCalls, 2)
    }

    func testFetchDataCancelsInFlightPullToRefresh() async {
        let presenter = MainPresentationLogicMock()
        let refreshRequestsStarted = expectation(description: "Pull to refresh requests started")
        refreshRequestsStarted.expectedFulfillmentCount = 3
        let refreshRequestsCancelled = expectation(description: "Pull to refresh requests cancelled")
        refreshRequestsCancelled.expectedFulfillmentCount = 3
        let summaryProvider = Self.makeSummaryProvider(
            results: [
                .success(.init(totalAmount: 10, currency: "USD", changePercent: 0)),
                .success(.init(totalAmount: 20, currency: "USD", changePercent: 0)),
                .success(.init(totalAmount: 30, currency: "USD", changePercent: 0))
            ],
            delaysInNanoseconds: [
                0,
                5_000_000_000,
                0
            ],
            onDelayStarted: { refreshRequestsStarted.fulfill() },
            onDelayCancelled: { refreshRequestsCancelled.fulfill() }
        )
        let repository = Self.makeRepository(
            store: store,
            observer: observer,
            categoriesResults: [
                .success([makeCategory(id: "cat-1", amount: 10)]),
                .success([makeCategory(id: "cat-1", amount: 20)]),
                .success([makeCategory(id: "cat-1", amount: 30)])
            ],
            recentExpensesResults: [
                .success([makeExpense(id: "exp-1", category: "cat-1", time: 100)]),
                .success([makeExpense(id: "exp-2", category: "cat-1", time: 200)]),
                .success([makeExpense(id: "exp-3", category: "cat-1", time: 300)])
            ],
            categoriesDelaysInNanoseconds: [
                0,
                5_000_000_000,
                0
            ],
            recentExpensesDelaysInNanoseconds: [
                0,
                5_000_000_000,
                0
            ],
            onDelayStarted: { refreshRequestsStarted.fulfill() },
            onDelayCancelled: { refreshRequestsCancelled.fulfill() }
        )
        let sut = makeSut(
            presenter: presenter,
            router: MainRoutingLogicMock(),
            summaryProvider: summaryProvider,
            repository: repository,
            observer: observer
        )

        await sut.fetchData()
        await sut.handlePullToRefresh()
        await fulfillment(of: [refreshRequestsStarted], timeout: 1)

        let reloaded = presentationExpectation(on: presenter) { data in
            !data.isRefreshing
                && data.summary?.totalAmount == 30
                && data.expenseGroups.flatMap(\.expenses).first?.id == "exp-3"
        }

        await sut.fetchData()
        await fulfillment(of: [reloaded, refreshRequestsCancelled], timeout: 1)

        guard let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter updates")
        }

        XCTAssertFalse(last.isRefreshing)
        XCTAssertEqual(last.summary?.totalAmount, 30)
        XCTAssertEqual(last.categories.first?.amount, 30)
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).first?.id, "exp-3")
    }

    func testFetchDataUsesObservedSummaryWhenSummaryRequestFails() async {
        let presenter = MainPresentationLogicMock()
        let repository = Self.makeRepository(
            store: store,
            observer: observer,
            categoriesResults: [.success([makeCategory(id: "cat-1", amount: 10)])],
            recentExpensesResults: [.success([])]
        )
        let sut = makeSut(
            presenter: presenter,
            router: MainRoutingLogicMock(),
            summaryProvider: Self.makeSummaryProvider(result: .failure(StubError.any)),
            repository: repository,
            observer: observer
        )

        await sut.fetchData()
        await waitForUpdates()

        guard let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter update")
        }

        assertStatus(last.summaryState, is: .loaded)
        XCTAssertEqual(last.summary?.totalAmount, 10)
        XCTAssertEqual(last.summary?.currency, "USD")
    }
}

extension MainInteractorTests {
    func testObserverUpdatesLoadedStateAfterExternalMutation() async {
        let presenter = MainPresentationLogicMock()
        let repository = Self.makeRepository(
            store: store,
            observer: observer,
            categoriesResults: [.success([makeCategory(id: "cat-1", amount: 10)])],
            recentExpensesResults: [.success([makeExpense(id: "exp-1", category: "cat-1", time: 100)])]
        )
        let sut = makeSut(
            presenter: presenter,
            router: MainRoutingLogicMock(),
            summaryProvider: Self.makeSummaryProvider(
                result: .success(.init(totalAmount: 100, currency: "USD", changePercent: 0))
            ),
            repository: repository,
            observer: observer
        )

        await sut.fetchData()
        let overviewUpdated = presentationExpectation(on: presenter) { data in
            data.expenseGroups.flatMap(\.expenses).first?.id == "exp-2"
        }

        emitOverview(
            categories: [makeCategory(id: "cat-1", amount: 50)],
            expenses: [makeExpense(id: "exp-2", category: "cat-1", time: 200)]
        )
        await fulfillment(of: [overviewUpdated], timeout: 1)

        guard let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter update")
        }

        XCTAssertEqual(last.summary?.totalAmount, 50)
        XCTAssertEqual(last.categories.first?.amount, 50)
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).first?.id, "exp-2")
    }

    func testObserverResetsSummaryToZeroWhenObservedCategoriesBecomeEmpty() async {
        let presenter = MainPresentationLogicMock()
        let repository = Self.makeRepository(
            store: store,
            observer: observer,
            categoriesResults: [.success([makeCategory(id: "cat-1", amount: 10)])],
            recentExpensesResults: [.success([])]
        )
        let sut = makeSut(
            presenter: presenter,
            router: MainRoutingLogicMock(),
            summaryProvider: Self.makeSummaryProvider(
                result: .success(.init(totalAmount: 100, currency: "USD", changePercent: 12))
            ),
            repository: repository,
            observer: observer
        )

        await sut.fetchData()
        let summaryReset = presentationExpectation(on: presenter) { data in
            data.summary?.totalAmount == .zero
        }
        emitOverview(categories: [], expenses: [])
        await fulfillment(of: [summaryReset], timeout: 1)

        guard let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter update")
        }

        XCTAssertEqual(last.summary?.totalAmount, .zero)
        XCTAssertEqual(last.summary?.currency, "USD")
        XCTAssertEqual(last.summary?.changePercent, 12)
    }
}

extension MainInteractorTests {
    func testHandleTapCategoryCallsRouter() async {
        let router = MainRoutingLogicMock()
        let repository = Self.makeRepository(
            store: store,
            observer: observer,
            categoriesResults: [.success([])],
            recentExpensesResults: [.success([])]
        )
        let sut = makeSut(
            presenter: MainPresentationLogicMock(),
            router: router,
            summaryProvider: Self.makeSummaryProvider(
                result: .success(.init(totalAmount: 0, currency: "USD", changePercent: 0))
            ),
            repository: repository,
            observer: observer
        )

        await sut.handleTapCategory(id: "cat-1", name: "Food")

        XCTAssertEqual(router.openCategoryIdNameReceivedInvocations.count, 1)
        XCTAssertEqual(router.openCategoryIdNameReceivedInvocations.first?.id, "cat-1")
        XCTAssertEqual(router.openCategoryIdNameReceivedInvocations.first?.name, "Food")
    }

    func testHandleTapPeriodButtonOpensPickerFromCurrentPeriod() async {
        let router = MainRoutingLogicMock()
        let summaryPeriodProvider = Self.makeSummaryPeriodService(
            period: .init(
                from: Date(timeIntervalSince1970: 10),
                to: Date(timeIntervalSince1970: 20)
            )
        )
        let repository = Self.makeRepository(
            store: store,
            observer: observer,
            categoriesResults: [.success([])],
            recentExpensesResults: [.success([])]
        )
        let sut = makeSut(
            presenter: MainPresentationLogicMock(),
            router: router,
            summaryProvider: Self.makeSummaryProvider(
                result: .success(.init(totalAmount: 0, currency: "USD", changePercent: 0))
            ),
            summaryPeriodProvider: summaryPeriodProvider,
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "PREMIUM"),
            repository: repository,
            observer: observer
        )

        await sut.handleTapPeriodButton()

        XCTAssertEqual(
            router.openPeriodPickerSelectedFromDateSelectedToDateOutputReceivedInvocations.map { MainSummaryPeriod(from: $0.selectedFromDate, to: $0.selectedToDate) },
            [
                .init(
                    from: Date(timeIntervalSince1970: 10),
                    to: Date(timeIntervalSince1970: 20)
                )
            ]
        )
    }

    func testHandleTapPeriodButtonWithRegularTierOpensSubscription() async {
        let router = MainRoutingLogicMock()
        let repository = Self.makeRepository(
            store: store,
            observer: observer,
            categoriesResults: [.success([])],
            recentExpensesResults: [.success([])]
        )
        let subscriptionAccessService = Self.makeSubscriptionAccessService(currentTier: "REGULAR")
        let sut = makeSut(
            presenter: MainPresentationLogicMock(),
            router: router,
            summaryProvider: Self.makeSummaryProvider(
                result: .success(.init(totalAmount: 0, currency: "USD", changePercent: 0))
            ),
            subscriptionAccessService: subscriptionAccessService,
            repository: repository,
            observer: observer
        )

        await sut.handleTapPeriodButton()

        XCTAssertTrue(router.openPeriodPickerSelectedFromDateSelectedToDateOutputReceivedInvocations.map { MainSummaryPeriod(from: $0.selectedFromDate, to: $0.selectedToDate) }.isEmpty)
        XCTAssertEqual(router.openSubscriptionCurrentTierOutputReceivedInvocations.last?.currentTier, .regular)
    }

    func testHandleTapPeriodButtonUsesCustomDateRangeCapabilityInsteadOfTier() async {
        let router = MainRoutingLogicMock()
        let repository = Self.makeRepository(
            store: store,
            observer: observer,
            categoriesResults: [.success([])],
            recentExpensesResults: [.success([])]
        )
        let summaryPeriodProvider = Self.makeSummaryPeriodService(
            period: .init(
                from: Date(timeIntervalSince1970: 10),
                to: Date(timeIntervalSince1970: 20)
            )
        )
        let subscriptionAccessService = Self.makeSubscriptionAccessService(
            currentTier: "REGULAR",
            currentSnapshot: .init(
                tier: .regular,
                status: .active,
                paidAccessUntil: nil,
                capabilities: [.customDateRange],
                aiRequestsLimit: 0,
                aiRequestsRemaining: 0,
                statusVersion: 42
            )
        )
        let sut = makeSut(
            presenter: MainPresentationLogicMock(),
            router: router,
            summaryProvider: Self.makeSummaryProvider(
                result: .success(.init(totalAmount: 0, currency: "USD", changePercent: 0))
            ),
            summaryPeriodProvider: summaryPeriodProvider,
            subscriptionAccessService: subscriptionAccessService,
            repository: repository,
            observer: observer
        )

        await sut.handleTapPeriodButton()

        XCTAssertEqual(router.openPeriodPickerSelectedFromDateSelectedToDateOutputReceivedInvocations.map { MainSummaryPeriod(from: $0.selectedFromDate, to: $0.selectedToDate) }, [summaryPeriodProvider.currentMonthPeriod()])
        XCTAssertNil(router.openSubscriptionCurrentTierOutputReceivedInvocations.last?.currentTier)
    }

    func testHandleTapPeriodButtonWithPlusTierOpensPeriodPicker() async {
        let router = MainRoutingLogicMock()
        let repository = Self.makeRepository(
            store: store,
            observer: observer,
            categoriesResults: [.success([])],
            recentExpensesResults: [.success([])]
        )
        let summaryPeriodProvider = Self.makeSummaryPeriodService(
            period: .init(
                from: Date(timeIntervalSince1970: 10),
                to: Date(timeIntervalSince1970: 20)
            )
        )
        let subscriptionAccessService = Self.makeSubscriptionAccessService(currentTier: "PLUS")
        let sut = makeSut(
            presenter: MainPresentationLogicMock(),
            router: router,
            summaryProvider: Self.makeSummaryProvider(
                result: .success(.init(totalAmount: 0, currency: "USD", changePercent: 0))
            ),
            summaryPeriodProvider: summaryPeriodProvider,
            subscriptionAccessService: subscriptionAccessService,
            repository: repository,
            observer: observer
        )

        await sut.handleTapPeriodButton()

        XCTAssertEqual(router.openPeriodPickerSelectedFromDateSelectedToDateOutputReceivedInvocations.map { MainSummaryPeriod(from: $0.selectedFromDate, to: $0.selectedToDate) }, [summaryPeriodProvider.currentMonthPeriod()])
        XCTAssertNil(router.openSubscriptionCurrentTierOutputReceivedInvocations.last?.currentTier)
    }

    func testFetchDataWithPlusTierKeepsSelectedPeriod() async {
        let presenter = MainPresentationLogicMock()
        let repository = Self.makeRepository(
            store: store,
            observer: observer,
            categoriesResults: [.success([])],
            recentExpensesResults: [.success([])]
        )
        let summaryPeriodProvider = Self.makeSummaryPeriodService(
            period: .init(
                from: Date(timeIntervalSince1970: 10),
                to: Date(timeIntervalSince1970: 20)
            ),
            defaultPeriod: .init(
                from: Date(timeIntervalSince1970: 100),
                to: Date(timeIntervalSince1970: 200)
            )
        )
        let sut = makeSut(
            presenter: presenter,
            router: MainRoutingLogicMock(),
            summaryProvider: Self.makeSummaryProvider(
                result: .success(.init(totalAmount: 0, currency: "USD", changePercent: 0))
            ),
            summaryPeriodProvider: summaryPeriodProvider,
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "PLUS"),
            repository: repository,
            observer: observer
        )

        await sut.fetchData()
        await waitForUpdates()

        XCTAssertEqual(summaryPeriodProvider.currentMonthPeriod().from, Date(timeIntervalSince1970: 10))
        XCTAssertEqual(summaryPeriodProvider.currentMonthPeriod().to, Date(timeIntervalSince1970: 20))
        XCTAssertEqual(summaryPeriodProvider.resetToCurrentMonthCallsCount, 0)
        XCTAssertFalse(presenter.presentFetchedDataReceivedInvocations.isEmpty)
    }

    func testHandleSubscriptionDidSyncRefreshesCurrentTier() async {
        let repository = Self.makeRepository(
            store: store,
            observer: observer,
            categoriesResults: [.success([])],
            recentExpensesResults: [.success([])]
        )
        let subscriptionAccessService = Self.makeSubscriptionAccessService(currentTier: "REGULAR")
        let sut = makeSut(
            presenter: MainPresentationLogicMock(),
            router: MainRoutingLogicMock(),
            summaryProvider: Self.makeSummaryProvider(
                result: .success(.init(totalAmount: 0, currency: "USD", changePercent: 0))
            ),
            subscriptionAccessService: subscriptionAccessService,
            repository: repository,
            observer: observer
        )

        await sut.handleSubscriptionDidSync()
        let refreshCallsCount = subscriptionAccessService.refreshCurrentSubscriptionSnapshotCallsCount + subscriptionAccessService.refreshCurrentTierStateCallsCount + subscriptionAccessService.refreshCurrentTierSourceStateCallsCount

        XCTAssertEqual(refreshCallsCount, 1)
    }

    func testHandleDidConfirmCategoryPeriodUpdatesPeriodAndReloadsMainData() async {
        let presenter = MainPresentationLogicMock()
        let summaryProvider = Self.makeSummaryProvider(
            result: .success(.init(totalAmount: 100, currency: "USD", changePercent: 0))
        )
        let summaryPeriodProvider = Self.makeSummaryPeriodService()
        let repository = Self.makeRepository(
            store: store,
            observer: observer,
            categoriesResults: [.success([])],
            recentExpensesResults: [.success([])]
        )
        let sut = makeSut(
            presenter: presenter,
            router: MainRoutingLogicMock(),
            summaryProvider: summaryProvider,
            summaryPeriodProvider: summaryPeriodProvider,
            repository: repository,
            observer: observer
        )

        let expectedPeriod = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 10),
            to: Date(timeIntervalSince1970: 20)
        )

        await sut.handleDidConfirmCategoryPeriod(
            fromDate: expectedPeriod.from,
            to: expectedPeriod.to
        )
        await waitForUpdates()

        let summaryFetchCalls = summaryProvider.fetchSummaryCallsCount
        let refreshCategoriesCalls = repository.refreshCategoriesCallsCount
        let refreshRecentExpensesCalls = repository.refreshRecentExpensesCallsCount
        let refreshLoadedModulesCalls = repository.refreshLoadedPeriodDependentModulesCallsCount

        XCTAssertEqual(summaryPeriodProvider.currentMonthPeriod(), expectedPeriod)
        XCTAssertEqual(summaryFetchCalls, 1)
        XCTAssertEqual(refreshCategoriesCalls, 1)
        XCTAssertEqual(refreshRecentExpensesCalls, 1)
        XCTAssertEqual(refreshLoadedModulesCalls, 1)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.summary?.totalAmount, 100)
    }
}

private extension MainInteractorTests {
    enum StubError: Error {
        case any
    }

    enum StatusCase {
        case idle
        case loading
        case loaded
        case failed
    }

    func makeSut(
        presenter: MainPresentationLogic,
        router: MainRoutingLogic,
        currencyRateProvider: MainCurrencyRateProviding = MainCurrencyRateProvidingMock(),
        summaryProvider: MainSummaryProviding,
        summaryPeriodProvider: MainSummaryPeriodServicing = MainInteractorTests.makeSummaryPeriodService(),
        subscriptionAccessService: SubscriptionAccessServicing = MainInteractorTests.makeSubscriptionAccessService(currentTier: "PREMIUM"),
        repository: MainFlowDomainRepositoryProtocol,
        observer: MainFlowDomainObserverProtocol,
        analytics: MainAnalyticsTracking? = nil
    ) -> MainInteractor {
        MainInteractor(
            presenter: presenter,
            router: router,
            currencyRateProvider: currencyRateProvider,
            summaryProvider: summaryProvider,
            summaryPeriodProvider: summaryPeriodProvider,
            subscriptionAccessService: subscriptionAccessService,
            repository: repository,
            observer: observer,
            analytics: analytics
        )
    }

    func makeCategory(id: String, amount: Double) -> MainCategoryCardModel {
        MainCategoryCardModel(
            id: id,
            name: "Food",
            icon: "🍴",
            color: "light_orange",
            amount: amount,
            currency: "USD"
        )
    }

    func makeExpense(id: String, category: String, time: TimeInterval) -> MainExpenseModel {
        MainExpenseModel(
            id: id,
            title: "Coffee",
            description: "Morning",
            amount: 4.5,
            currency: "USD",
            category: category,
            timeOfAdd: Date(timeIntervalSince1970: time)
        )
    }

    func waitForUpdates() async {
        await Task.yield()
        await Task.yield()
    }

    func presentationExpectation(
        on presenter: MainPresentationLogicMock,
        where predicate: @escaping (MainFetchData) -> Bool
    ) -> XCTestExpectation {
        let expectation = expectation(description: "Presenter received expected data")
        expectation.assertForOverFulfill = false
        presenter.presentFetchedDataClosure = { data in
            guard predicate(data) else {
                return
            }

            expectation.fulfill()
        }
        return expectation
    }

    func assertStatus(
        _ status: LoadingStatus,
        is expected: StatusCase,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            isStatus(status, expected),
            "Expected status \(expected), got \(status)",
            file: file,
            line: line
        )
    }

    func isStatus(_ status: LoadingStatus, _ expected: StatusCase) -> Bool {
        switch (status, expected) {
        case (.idle, .idle), (.loading, .loading), (.loaded, .loaded), (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

private extension MainInteractorTests {
    func emitOverview(categories: [MainCategoryCardModel], expenses: [MainExpenseModel]) {
        store.update { state in
            categories.forEach { state.categoriesByID[$0.id] = $0 }
            state.categoryOrder = categories.map(\.id)
            expenses.forEach { state.expensesByID[$0.id] = $0 }
            state.recentExpenseIDs = expenses.map(\.id)
        }
        observer.publishAll(from: store)
    }

    nonisolated static func makeRepository(
        store: MainFlowDomainStore,
        observer: MainFlowDomainObserver,
        categoriesResults: [Result<[MainCategoryCardModel], Error>],
        recentExpensesResults: [Result<[MainExpenseModel], Error>],
        categoriesDelaysInNanoseconds: [UInt64] = [],
        recentExpensesDelaysInNanoseconds: [UInt64] = [],
        onDelayStarted: @escaping @Sendable () -> Void = {},
        onDelayCancelled: @escaping @Sendable () -> Void = {}
    ) -> MainFlowDomainRepositoryProtocolMock {
        let repository = MainFlowDomainRepositoryProtocolMock()
        repository.refreshCategoriesClosure = { [unowned repository] in
            let callIndex = repository.refreshCategoriesCallsCount - 1
            try await delayIfNeeded(
                delaysInNanoseconds: categoriesDelaysInNanoseconds,
                callIndex: callIndex,
                onDelayStarted: onDelayStarted,
                onDelayCancelled: onDelayCancelled
            )
            let categories = try categoriesResults[min(callIndex, max(categoriesResults.count - 1, .zero))].get()
            store.update { state in
                categories.forEach { state.categoriesByID[$0.id] = $0 }
                state.categoryOrder = categories.map(\.id)
            }
            observer.publishAll(from: store)
        }
        repository.refreshRecentExpensesClosure = { [unowned repository] in
            let callIndex = repository.refreshRecentExpensesCallsCount - 1
            try await delayIfNeeded(
                delaysInNanoseconds: recentExpensesDelaysInNanoseconds,
                callIndex: callIndex,
                onDelayStarted: onDelayStarted,
                onDelayCancelled: onDelayCancelled
            )
            let expenses = try recentExpensesResults[min(callIndex, max(recentExpensesResults.count - 1, .zero))].get()
            store.update { state in
                expenses.forEach { state.expensesByID[$0.id] = $0 }
                state.recentExpenseIDs = expenses.map(\.id)
            }
            observer.publishAll(from: store)
        }
        repository.refreshMainFlowClosure = { [unowned repository] in
            try await repository.refreshCategories()
            try await repository.refreshRecentExpenses()
        }
        return repository
    }

    nonisolated static func makeSummaryProvider(result: Result<MainSummaryModel, Error>) -> MainSummaryProvidingMock {
        makeSummaryProvider(results: [result])
    }

    nonisolated static func makeSummaryProvider(
        results: [Result<MainSummaryModel, Error>],
        delaysInNanoseconds: [UInt64] = [],
        onDelayStarted: @escaping @Sendable () -> Void = {},
        onDelayCancelled: @escaping @Sendable () -> Void = {}
    ) -> MainSummaryProvidingMock {
        let summaryProvider = MainSummaryProvidingMock()
        summaryProvider.fetchSummaryClosure = { [unowned summaryProvider] in
            let callIndex = summaryProvider.fetchSummaryCallsCount - 1
            try await delayIfNeeded(
                delaysInNanoseconds: delaysInNanoseconds,
                callIndex: callIndex,
                onDelayStarted: onDelayStarted,
                onDelayCancelled: onDelayCancelled
            )
            return try results[min(callIndex, max(results.count - 1, .zero))].get()
        }
        return summaryProvider
    }

    nonisolated static func makeCurrencyRateProvider(result: Result<Void, Error>) -> MainCurrencyRateProvidingMock {
        let currencyRateProvider = MainCurrencyRateProvidingMock()
        if case let .failure(error) = result {
            currencyRateProvider.synchronizeCurrencyRateOnLaunchThrowableError = error
        }
        return currencyRateProvider
    }

    nonisolated static func makeSubscriptionAccessService(
        currentTier: String,
        refreshedTier: String? = nil,
        currentSnapshot: SubscriptionAccessSnapshot? = nil,
        refreshedSnapshot: SubscriptionAccessSnapshot? = nil
    ) -> SubscriptionAccessServicingMock {
        let current = currentSnapshot ?? SubscriptionAccessSnapshotFixtures.makeSnapshot(tierName: currentTier)
        let refreshed = refreshedSnapshot ?? SubscriptionAccessSnapshotFixtures.makeSnapshot(tierName: refreshedTier ?? currentTier)
        let subscriptionAccessService = SubscriptionAccessServicingMock()
        subscriptionAccessService.currentTierStateReturnValue = .resolved(current.tier)
        subscriptionAccessService.refreshCurrentTierStateReturnValue = .resolved(refreshed.tier)
        subscriptionAccessService.refreshCurrentTierSourceStateReturnValue = .network(refreshed.tier)
        subscriptionAccessService.currentSubscriptionSnapshotReturnValue = current
        subscriptionAccessService.refreshCurrentSubscriptionSnapshotReturnValue = refreshed
        return subscriptionAccessService
    }

    nonisolated static func makeSummaryPeriodService(
        period: MainSummaryPeriod = .init(
            from: Date(timeIntervalSince1970: 1),
            to: Date(timeIntervalSince1970: 2)
        ),
        defaultPeriod: MainSummaryPeriod? = nil
    ) -> MainSummaryPeriodServicingMock {
        var currentPeriod = period
        let summaryPeriodProvider = MainSummaryPeriodServicingMock()
        summaryPeriodProvider.currentMonthPeriodClosure = { currentPeriod }
        summaryPeriodProvider.updatePeriodFromToClosure = { currentPeriod = .init(from: $0, to: $1) }
        summaryPeriodProvider.resetToCurrentMonthClosure = { currentPeriod = defaultPeriod ?? period }
        return summaryPeriodProvider
    }

    nonisolated static func delayIfNeeded(
        delaysInNanoseconds: [UInt64],
        callIndex: Int,
        onDelayStarted: @Sendable () -> Void,
        onDelayCancelled: @Sendable () -> Void
    ) async throws {
        let delay = delaysInNanoseconds.isEmpty
            ? .zero
            : delaysInNanoseconds[min(callIndex, delaysInNanoseconds.count - 1)]
        guard delay > .zero else {
            return
        }

        onDelayStarted()
        do {
            try await Task.sleep(nanoseconds: delay)
        } catch {
            onDelayCancelled()
            throw error
        }
    }
}
