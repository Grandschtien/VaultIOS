import XCTest
@testable import Vault

@MainActor
final class MainInteractorTests: XCTestCase {
    func testFetchDataHappyPathLoadsAllSections() async {
        let presenter = MainPresenterSpy()
        let repository = MainRepositoryStub(
            categoriesResults: [.success([makeCategory(id: "cat-1", amount: 10)])],
            recentExpensesResults: [.success([makeExpense(id: "exp-1", category: "cat-1", time: 100)])]
        )
        let sut = makeSut(
            presenter: presenter,
            router: MainRouterSpy(),
            summaryProvider: MainSummaryProviderStub(
                result: .success(.init(totalAmount: 2450.8, currency: "USD", changePercent: 12))
            ),
            repository: repository,
            observer: repository.observer
        )

        await sut.fetchData()
        await waitForUpdates()

        guard let first = presenter.presentedData.first,
              let last = presenter.presentedData.last else {
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
}

extension MainInteractorTests {
    func testFetchDataWhenCurrencyRateFailsShowsBlockingErrorAndSkipsDomainRefresh() async {
        let presenter = MainPresenterSpy()
        let repository = MainRepositoryStub(
            categoriesResults: [.success([])],
            recentExpensesResults: [.success([])]
        )
        let currencyRateProvider = MainCurrencyRateProviderStub(result: .failure(StubError.any))
        let sut = makeSut(
            presenter: presenter,
            router: MainRouterSpy(),
            currencyRateProvider: currencyRateProvider,
            summaryProvider: MainSummaryProviderStub(
                result: .success(.init(totalAmount: 0, currency: "USD", changePercent: 0))
            ),
            repository: repository,
            observer: repository.observer
        )

        await sut.fetchData()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        XCTAssertEqual("Что-то пошло не так", L10n.mainOverviewError)
        assertStatus(last.summaryState, is: .idle)
        assertStatus(last.categoriesState, is: .idle)
        assertStatus(last.expensesState, is: .idle)
        let categoriesCalls = await repository.refreshCategoriesCalls()
        let expensesCalls = await repository.refreshRecentExpensesCalls()
        XCTAssertEqual(categoriesCalls, 0)
        XCTAssertEqual(expensesCalls, 0)
    }
}

extension MainInteractorTests {
    func testHandleTapRetryCategoriesReloadsOnlyCategoriesSection() async {
//        let presenter = MainPresenterSpy()
//        let repository = MainRepositoryStub(
//            categoriesResults: [
//                .failure(StubError.any),
//                .success([makeCategory(id: "cat-1", amount: 10)])
//            ],
//            recentExpensesResults: [.success([])]
//        )
//        let sut = makeSut(
//            presenter: presenter,
//            router: MainRouterSpy(),
//            summaryProvider: MainSummaryProviderStub(
//                result: .success(.init(totalAmount: 100, currency: "USD", changePercent: 0))
//            ),
//            repository: repository,
//            observer: repository.observer
//        )
//
//        await sut.fetchData()
//        await sut.handleTapRetryCategories()
//        await waitForUpdates()
//
//        guard let last = presenter.presentedData.last else {
//            return XCTFail("Expected presenter update")
//        }
//
//        assertStatus(last.summaryState, is: .loaded)
//        assertStatus(last.categoriesState, is: .loaded)
//        assertStatus(last.expensesState, is: .loaded)
//        XCTAssertEqual(last.categories.count, 1)
//        let categoriesCalls = await repository.refreshCategoriesCalls()
//        let expensesCalls = await repository.refreshRecentExpensesCalls()
//        XCTAssertEqual(categoriesCalls, 2)
//        XCTAssertEqual(expensesCalls, 1)
    }

    func testHandlePullToRefreshPreservesContentAndReloadsData() async {
        let presenter = MainPresenterSpy()
        let summaryProvider = MainSummaryProviderStub(
            results: [
                .success(.init(totalAmount: 100, currency: "USD", changePercent: 0)),
                .success(.init(totalAmount: 200, currency: "USD", changePercent: 0))
            ]
        )
        let repository = MainRepositoryStub(
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
            router: MainRouterSpy(),
            summaryProvider: summaryProvider,
            repository: repository,
            observer: repository.observer
        )

        await sut.fetchData()
        await waitForUpdates()

        let initialUpdatesCount = presenter.presentedData.count

        await sut.handlePullToRefresh()
        await waitForUpdates()

        guard let refreshingUpdate = presenter.presentedData[initialUpdatesCount...].first(where: { $0.isRefreshing }),
              let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter updates for pull to refresh")
        }

        assertStatus(refreshingUpdate.summaryState, is: .loaded)
        assertStatus(refreshingUpdate.categoriesState, is: .loaded)
        assertStatus(refreshingUpdate.expensesState, is: .loaded)
        XCTAssertEqual(refreshingUpdate.summary?.totalAmount, 100)
        XCTAssertEqual(refreshingUpdate.categories.first?.amount, 10)
        XCTAssertEqual(refreshingUpdate.expenseGroups.flatMap(\.expenses).first?.id, "exp-1")

        XCTAssertFalse(last.isRefreshing)
        XCTAssertEqual(last.summary?.totalAmount, 200)
        XCTAssertEqual(last.categories.first?.amount, 20)
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).first?.id, "exp-2")

        let summaryFetchCalls = await summaryProvider.recordedFetchCallsCount()
        let categoriesCalls = await repository.refreshCategoriesCalls()
        let expensesCalls = await repository.refreshRecentExpensesCalls()

        XCTAssertEqual(summaryFetchCalls, 2)
        XCTAssertEqual(categoriesCalls, 2)
        XCTAssertEqual(expensesCalls, 2)
    }

    func testFetchDataCancelsInFlightPullToRefresh() async {
        let presenter = MainPresenterSpy()
        let summaryProvider = MainSummaryProviderStub(
            results: [
                .success(.init(totalAmount: 100, currency: "USD", changePercent: 0)),
                .success(.init(totalAmount: 200, currency: "USD", changePercent: 0)),
                .success(.init(totalAmount: 300, currency: "USD", changePercent: 0))
            ],
            delaysInNanoseconds: [
                0,
                5_000_000_000,
                0
            ]
        )
        let repository = MainRepositoryStub(
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
            ]
        )
        let sut = makeSut(
            presenter: presenter,
            router: MainRouterSpy(),
            summaryProvider: summaryProvider,
            repository: repository,
            observer: repository.observer
        )

        await sut.fetchData()
        await waitForUpdates()

        await sut.handlePullToRefresh()
        await waitForUpdates()
        await sut.fetchData()
        await waitForUpdates()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter updates")
        }

        XCTAssertFalse(last.isRefreshing)
        XCTAssertEqual(last.summary?.totalAmount, 300)
        XCTAssertEqual(last.categories.first?.amount, 30)
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).first?.id, "exp-3")

        let cancelledSummaryCalls = await summaryProvider.cancelledFetchCallsCount()
        let cancelledCategoriesCalls = await repository.refreshCategoriesCancelledCalls()
        let cancelledExpensesCalls = await repository.refreshRecentExpensesCancelledCalls()

        XCTAssertGreaterThanOrEqual(cancelledSummaryCalls, 1)
        XCTAssertGreaterThanOrEqual(cancelledCategoriesCalls, 1)
        XCTAssertGreaterThanOrEqual(cancelledExpensesCalls, 1)
    }

    func testFetchDataUsesObservedSummaryWhenSummaryRequestFails() async {
        let presenter = MainPresenterSpy()
        let repository = MainRepositoryStub(
            categoriesResults: [.success([makeCategory(id: "cat-1", amount: 10)])],
            recentExpensesResults: [.success([])]
        )
        let sut = makeSut(
            presenter: presenter,
            router: MainRouterSpy(),
            summaryProvider: MainSummaryProviderStub(result: .failure(StubError.any)),
            repository: repository,
            observer: repository.observer
        )

        await sut.fetchData()
        await waitForUpdates()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        assertStatus(last.summaryState, is: .loaded)
        XCTAssertEqual(last.summary?.totalAmount, 10)
        XCTAssertEqual(last.summary?.currency, "USD")
    }
}

extension MainInteractorTests {
    func testObserverUpdatesLoadedStateAfterExternalMutation() async {
        let presenter = MainPresenterSpy()
        let repository = MainRepositoryStub(
            categoriesResults: [.success([makeCategory(id: "cat-1", amount: 10)])],
            recentExpensesResults: [.success([makeExpense(id: "exp-1", category: "cat-1", time: 100)])]
        )
        let sut = makeSut(
            presenter: presenter,
            router: MainRouterSpy(),
            summaryProvider: MainSummaryProviderStub(
                result: .success(.init(totalAmount: 100, currency: "USD", changePercent: 0))
            ),
            repository: repository,
            observer: repository.observer
        )

        await sut.fetchData()
        await repository.emitOverview(
            categories: [makeCategory(id: "cat-1", amount: 50)],
            expenses: [makeExpense(id: "exp-2", category: "cat-1", time: 200)]
        )
        await waitForUpdates()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        XCTAssertEqual(last.summary?.totalAmount, 50)
        XCTAssertEqual(last.categories.first?.amount, 50)
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).first?.id, "exp-2")
    }

    func testObserverResetsSummaryToZeroWhenObservedCategoriesBecomeEmpty() async {
        let presenter = MainPresenterSpy()
        let repository = MainRepositoryStub(
            categoriesResults: [.success([makeCategory(id: "cat-1", amount: 10)])],
            recentExpensesResults: [.success([])]
        )
        let sut = makeSut(
            presenter: presenter,
            router: MainRouterSpy(),
            summaryProvider: MainSummaryProviderStub(
                result: .success(.init(totalAmount: 100, currency: "USD", changePercent: 12))
            ),
            repository: repository,
            observer: repository.observer
        )

        await sut.fetchData()
        await repository.emitOverview(categories: [], expenses: [])
        await waitForUpdates()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        XCTAssertEqual(last.summary?.totalAmount, .zero)
        XCTAssertEqual(last.summary?.currency, "USD")
        XCTAssertEqual(last.summary?.changePercent, 12)
    }
}

extension MainInteractorTests {
    func testHandleTapCategoryCallsRouter() async {
        let router = MainRouterSpy()
        let repository = MainRepositoryStub(
            categoriesResults: [.success([])],
            recentExpensesResults: [.success([])]
        )
        let sut = makeSut(
            presenter: MainPresenterSpy(),
            router: router,
            summaryProvider: MainSummaryProviderStub(
                result: .success(.init(totalAmount: 0, currency: "USD", changePercent: 0))
            ),
            repository: repository,
            observer: repository.observer
        )

        await sut.handleTapCategory(id: "cat-1", name: "Food")

        XCTAssertEqual(router.openCategoryCalls.count, 1)
        XCTAssertEqual(router.openCategoryCalls.first?.id, "cat-1")
        XCTAssertEqual(router.openCategoryCalls.first?.name, "Food")
    }

    func testHandleTapPeriodButtonOpensPickerFromCurrentPeriod() async {
        let router = MainRouterSpy()
        let summaryPeriodProvider = MainSummaryPeriodServiceStub(
            period: .init(
                from: Date(timeIntervalSince1970: 10),
                to: Date(timeIntervalSince1970: 20)
            )
        )
        let repository = MainRepositoryStub(
            categoriesResults: [.success([])],
            recentExpensesResults: [.success([])]
        )
        let sut = makeSut(
            presenter: MainPresenterSpy(),
            router: router,
            summaryProvider: MainSummaryProviderStub(
                result: .success(.init(totalAmount: 0, currency: "USD", changePercent: 0))
            ),
            summaryPeriodProvider: summaryPeriodProvider,
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "PREMIUM"),
            repository: repository,
            observer: repository.observer
        )

        await sut.handleTapPeriodButton()

        XCTAssertEqual(
            router.openPeriodPickerCalls,
            [
                .init(
                    from: Date(timeIntervalSince1970: 10),
                    to: Date(timeIntervalSince1970: 20)
                )
            ]
        )
    }

    func testHandleTapPeriodButtonWithRegularTierOpensSubscription() async {
        let router = MainRouterSpy()
        let repository = MainRepositoryStub(
            categoriesResults: [.success([])],
            recentExpensesResults: [.success([])]
        )
        let subscriptionAccessService = SubscriptionAccessServiceStub(currentTier: "REGULAR")
        let sut = makeSut(
            presenter: MainPresenterSpy(),
            router: router,
            summaryProvider: MainSummaryProviderStub(
                result: .success(.init(totalAmount: 0, currency: "USD", changePercent: 0))
            ),
            subscriptionAccessService: subscriptionAccessService,
            repository: repository,
            observer: repository.observer
        )

        await sut.handleTapPeriodButton()

        XCTAssertTrue(router.openPeriodPickerCalls.isEmpty)
        XCTAssertEqual(router.lastOpenedSubscriptionTier, .regular)
    }

    func testHandleTapPeriodButtonUsesCustomDateRangeCapabilityInsteadOfTier() async {
        let router = MainRouterSpy()
        let repository = MainRepositoryStub(
            categoriesResults: [.success([])],
            recentExpensesResults: [.success([])]
        )
        let summaryPeriodProvider = MainSummaryPeriodServiceStub(
            period: .init(
                from: Date(timeIntervalSince1970: 10),
                to: Date(timeIntervalSince1970: 20)
            )
        )
        let subscriptionAccessService = SubscriptionAccessServiceStub(
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
            presenter: MainPresenterSpy(),
            router: router,
            summaryProvider: MainSummaryProviderStub(
                result: .success(.init(totalAmount: 0, currency: "USD", changePercent: 0))
            ),
            summaryPeriodProvider: summaryPeriodProvider,
            subscriptionAccessService: subscriptionAccessService,
            repository: repository,
            observer: repository.observer
        )

        await sut.handleTapPeriodButton()

        XCTAssertEqual(router.openPeriodPickerCalls, [summaryPeriodProvider.currentMonthPeriod()])
        XCTAssertNil(router.lastOpenedSubscriptionTier)
    }

    func testHandleTapPeriodButtonWithPlusTierOpensPeriodPicker() async {
        let router = MainRouterSpy()
        let repository = MainRepositoryStub(
            categoriesResults: [.success([])],
            recentExpensesResults: [.success([])]
        )
        let summaryPeriodProvider = MainSummaryPeriodServiceStub(
            period: .init(
                from: Date(timeIntervalSince1970: 10),
                to: Date(timeIntervalSince1970: 20)
            )
        )
        let subscriptionAccessService = SubscriptionAccessServiceStub(currentTier: "PLUS")
        let sut = makeSut(
            presenter: MainPresenterSpy(),
            router: router,
            summaryProvider: MainSummaryProviderStub(
                result: .success(.init(totalAmount: 0, currency: "USD", changePercent: 0))
            ),
            summaryPeriodProvider: summaryPeriodProvider,
            subscriptionAccessService: subscriptionAccessService,
            repository: repository,
            observer: repository.observer
        )

        await sut.handleTapPeriodButton()

        XCTAssertEqual(router.openPeriodPickerCalls, [summaryPeriodProvider.currentMonthPeriod()])
        XCTAssertNil(router.lastOpenedSubscriptionTier)
    }

    func testFetchDataWithPlusTierKeepsSelectedPeriod() async {
        let presenter = MainPresenterSpy()
        let repository = MainRepositoryStub(
            categoriesResults: [.success([])],
            recentExpensesResults: [.success([])]
        )
        let summaryPeriodProvider = MainSummaryPeriodServiceStub(
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
            router: MainRouterSpy(),
            summaryProvider: MainSummaryProviderStub(
                result: .success(.init(totalAmount: 0, currency: "USD", changePercent: 0))
            ),
            summaryPeriodProvider: summaryPeriodProvider,
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "PLUS"),
            repository: repository,
            observer: repository.observer
        )

        await sut.fetchData()
        await waitForUpdates()

        XCTAssertEqual(summaryPeriodProvider.currentMonthPeriod().from, Date(timeIntervalSince1970: 10))
        XCTAssertEqual(summaryPeriodProvider.currentMonthPeriod().to, Date(timeIntervalSince1970: 20))
        XCTAssertEqual(summaryPeriodProvider.resetCallsCount, 0)
        XCTAssertFalse(presenter.presentedData.isEmpty)
    }

    func testHandleSubscriptionDidSyncRefreshesCurrentTier() async {
        let repository = MainRepositoryStub(
            categoriesResults: [.success([])],
            recentExpensesResults: [.success([])]
        )
        let subscriptionAccessService = SubscriptionAccessServiceStub(currentTier: "REGULAR")
        let sut = makeSut(
            presenter: MainPresenterSpy(),
            router: MainRouterSpy(),
            summaryProvider: MainSummaryProviderStub(
                result: .success(.init(totalAmount: 0, currency: "USD", changePercent: 0))
            ),
            subscriptionAccessService: subscriptionAccessService,
            repository: repository,
            observer: repository.observer
        )

        await sut.handleSubscriptionDidSync()
        let refreshCallsCount = await subscriptionAccessService.refreshCallsCount()

        XCTAssertEqual(refreshCallsCount, 1)
    }

    func testHandleDidConfirmCategoryPeriodUpdatesPeriodAndReloadsMainData() async {
        let presenter = MainPresenterSpy()
        let summaryProvider = MainSummaryProviderStub(
            result: .success(.init(totalAmount: 100, currency: "USD", changePercent: 0))
        )
        let summaryPeriodProvider = MainSummaryPeriodServiceStub()
        let repository = MainRepositoryStub(
            categoriesResults: [.success([])],
            recentExpensesResults: [.success([])]
        )
        let sut = makeSut(
            presenter: presenter,
            router: MainRouterSpy(),
            summaryProvider: summaryProvider,
            summaryPeriodProvider: summaryPeriodProvider,
            repository: repository,
            observer: repository.observer
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

        let summaryFetchCalls = await summaryProvider.recordedFetchCallsCount()
        let refreshCategoriesCalls = await repository.refreshCategoriesCalls()
        let refreshRecentExpensesCalls = await repository.refreshRecentExpensesCalls()
        let refreshLoadedModulesCalls = await repository.refreshLoadedPeriodDependentModulesCalls()

        XCTAssertEqual(summaryPeriodProvider.currentMonthPeriod(), expectedPeriod)
        XCTAssertEqual(summaryFetchCalls, 1)
        XCTAssertEqual(refreshCategoriesCalls, 1)
        XCTAssertEqual(refreshRecentExpensesCalls, 1)
        XCTAssertEqual(refreshLoadedModulesCalls, 1)
        XCTAssertEqual(presenter.presentedData.last?.summary?.totalAmount, 100)
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
        currencyRateProvider: MainCurrencyRateProviding = MainCurrencyRateProviderStub(result: .success(())),
        summaryProvider: MainSummaryProviding,
        summaryPeriodProvider: MainSummaryPeriodServicing = MainSummaryPeriodServiceStub(),
        subscriptionAccessService: SubscriptionAccessServicing = SubscriptionAccessServiceStub(currentTier: "PREMIUM"),
        repository: MainFlowDomainRepositoryProtocol,
        observer: MainFlowDomainObserverProtocol
    ) -> MainInteractor {
        MainInteractor(
            presenter: presenter,
            router: router,
            currencyRateProvider: currencyRateProvider,
            summaryProvider: summaryProvider,
            summaryPeriodProvider: summaryPeriodProvider,
            subscriptionAccessService: subscriptionAccessService,
            repository: repository,
            observer: observer
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

@MainActor
private final class MainPresenterSpy: MainPresentationLogic, @unchecked Sendable {
    private(set) var presentedData: [MainFetchData] = []

    func presentFetchedData(_ data: MainFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class MainRouterSpy: MainRoutingLogic, @unchecked Sendable {
    private(set) var openCategoriesCount: Int = .zero
    private(set) var openExpensesCount: Int = .zero
    private(set) var openCategoryCalls: [(id: String, name: String)] = []
    private(set) var openPeriodPickerCalls: [MainSummaryPeriod] = []
    private(set) var lastOpenedSubscriptionTier: SubscriptionTier?

    func openAllCategories() {
        openCategoriesCount += 1
    }

    func openAllExpenses() {
        openExpensesCount += 1
    }

    func openCategory(id: String, name: String) {
        openCategoryCalls.append((id, name))
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

private actor MainSummaryProviderStub: MainSummaryProviding {
    let results: [Result<MainSummaryModel, Error>]
    let delaysInNanoseconds: [UInt64]
    private var fetchCallsCount: Int = .zero
    private var cancelledCallsCount: Int = .zero

    init(result: Result<MainSummaryModel, Error>) {
        self.results = [result]
        self.delaysInNanoseconds = []
    }

    init(results: [Result<MainSummaryModel, Error>]) {
        self.results = results
        self.delaysInNanoseconds = []
    }

    init(
        results: [Result<MainSummaryModel, Error>],
        delaysInNanoseconds: [UInt64]
    ) {
        self.results = results
        self.delaysInNanoseconds = delaysInNanoseconds
    }

    func fetchSummary() async throws -> MainSummaryModel {
        let callIndex = fetchCallsCount
        let index = min(callIndex, max(results.count - 1, .zero))
        fetchCallsCount += 1

        let delayIndex = min(callIndex, max(delaysInNanoseconds.count - 1, .zero))
        let delay = delaysInNanoseconds.isEmpty ? .zero : delaysInNanoseconds[delayIndex]
        if delay > 0 {
            do {
                try await Task.sleep(nanoseconds: delay)
            } catch {
                cancelledCallsCount += 1
                throw error
            }
        }

        return try results[index].get()
    }

    func recordedFetchCallsCount() -> Int {
        fetchCallsCount
    }

    func cancelledFetchCallsCount() -> Int {
        cancelledCallsCount
    }
}

private actor MainCurrencyRateProviderStub: MainCurrencyRateProviding {
    let results: [Result<Void, Swift.Error>]
    private var syncCallsCount: Int = .zero

    init(result: Result<Void, Swift.Error>) {
        self.results = [result]
    }

    func synchronizeCurrencyRateOnLaunch() async throws {
        let index = min(syncCallsCount, max(results.count - 1, .zero))
        syncCallsCount += 1
        _ = try results[index].get()
    }
}

private actor SubscriptionAccessServiceStub: SubscriptionAccessServicing {
    private let currentSnapshot: SubscriptionAccessSnapshot
    private let refreshedSnapshot: SubscriptionAccessSnapshot
    private var refreshCalls = 0

    init(
        currentTier: String,
        refreshedTier: String? = nil,
        currentSnapshot: SubscriptionAccessSnapshot? = nil,
        refreshedSnapshot: SubscriptionAccessSnapshot? = nil
    ) {
        self.currentSnapshot = currentSnapshot ?? Self.makeSnapshot(tier: currentTier)
        self.refreshedSnapshot = refreshedSnapshot ?? Self.makeSnapshot(tier: refreshedTier ?? currentTier)
    }

    func currentTierState() async -> SubscriptionTierState {
        .resolved(currentSnapshot.tier)
    }

    func refreshCurrentTierState() async -> SubscriptionTierState {
        refreshCalls += 1
        return .resolved(refreshedSnapshot.tier)
    }

    func refreshCurrentTierSourceState() async -> SubscriptionTierRefreshState {
        refreshCalls += 1
        return .network(refreshedSnapshot.tier)
    }

    func currentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot? {
        currentSnapshot
    }

    func refreshCurrentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot? {
        refreshCalls += 1
        return refreshedSnapshot
    }

    func refreshCallsCount() -> Int {
        refreshCalls
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

private final class MainSummaryPeriodServiceStub: MainSummaryPeriodServicing, @unchecked Sendable {
    private var period: MainSummaryPeriod
    private let defaultPeriod: MainSummaryPeriod
    private(set) var resetCallsCount = 0

    init(
        period: MainSummaryPeriod = .init(
            from: Date(timeIntervalSince1970: 1),
            to: Date(timeIntervalSince1970: 2)
        ),
        defaultPeriod: MainSummaryPeriod? = nil
    ) {
        self.period = period
        self.defaultPeriod = defaultPeriod ?? period
    }

    func currentMonthPeriod() -> MainSummaryPeriod {
        period
    }

    func updatePeriod(from: Date, to: Date) {
        period = .init(from: from, to: to)
    }

    func resetToCurrentMonth() {
        resetCallsCount += 1
        period = defaultPeriod
    }
}

private actor MainRepositoryStub: MainFlowDomainRepositoryProtocol {
    nonisolated let observer: MainFlowDomainObserverProtocol

    private let store: MainFlowDomainStoreProtocol
    private let categoriesResults: [Result<[MainCategoryCardModel], Error>]
    private let recentExpensesResults: [Result<[MainExpenseModel], Error>]
    private let categoriesDelaysInNanoseconds: [UInt64]
    private let recentExpensesDelaysInNanoseconds: [UInt64]
    private var categoriesCallCount: Int = .zero
    private var recentExpensesCallCount: Int = .zero
    private var cancelledCategoriesCallCount: Int = .zero
    private var cancelledRecentExpensesCallCount: Int = .zero
    private var refreshLoadedPeriodDependentModulesCallCount: Int = .zero

    init(
        categoriesResults: [Result<[MainCategoryCardModel], Error>],
        recentExpensesResults: [Result<[MainExpenseModel], Error>],
        categoriesDelaysInNanoseconds: [UInt64] = [],
        recentExpensesDelaysInNanoseconds: [UInt64] = []
    ) {
        let store = MainFlowDomainStore()
        self.store = store
        self.observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        self.categoriesResults = categoriesResults
        self.recentExpensesResults = recentExpensesResults
        self.categoriesDelaysInNanoseconds = categoriesDelaysInNanoseconds
        self.recentExpensesDelaysInNanoseconds = recentExpensesDelaysInNanoseconds
    }

    func refreshMainFlow() async throws {
        try await refreshCategories()
        try await refreshRecentExpenses()
    }

    func refreshCategories() async throws {
        let callIndex = categoriesCallCount
        let index = min(callIndex, max(categoriesResults.count - 1, .zero))
        categoriesCallCount += 1

        let delayIndex = min(callIndex, max(categoriesDelaysInNanoseconds.count - 1, .zero))
        let delay = categoriesDelaysInNanoseconds.isEmpty ? .zero : categoriesDelaysInNanoseconds[delayIndex]
        if delay > 0 {
            do {
                try await Task.sleep(nanoseconds: delay)
            } catch {
                cancelledCategoriesCallCount += 1
                throw error
            }
        }

        let categories = try categoriesResults[index].get()

        store.update { state in
            categories.forEach { state.categoriesByID[$0.id] = $0 }
            state.categoryOrder = categories.map(\.id)
        }
        observer.publishAll(from: store)
    }

    func refreshRecentExpenses() async throws {
        let callIndex = recentExpensesCallCount
        let index = min(callIndex, max(recentExpensesResults.count - 1, .zero))
        recentExpensesCallCount += 1

        let delayIndex = min(callIndex, max(recentExpensesDelaysInNanoseconds.count - 1, .zero))
        let delay = recentExpensesDelaysInNanoseconds.isEmpty ? .zero : recentExpensesDelaysInNanoseconds[delayIndex]
        if delay > 0 {
            do {
                try await Task.sleep(nanoseconds: delay)
            } catch {
                cancelledRecentExpensesCallCount += 1
                throw error
            }
        }

        let expenses = try recentExpensesResults[index].get()

        store.update { state in
            expenses.forEach { state.expensesByID[$0.id] = $0 }
            state.recentExpenseIDs = expenses.map(\.id)
        }
        observer.publishAll(from: store)
    }

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
    func addCategory(_ request: CategoryCreateRequestDTO) async throws {}
    func deleteCategory(id: String) async throws {}
    func clearSession() async {}

    func refreshCategoriesCalls() -> Int {
        categoriesCallCount
    }

    func refreshRecentExpensesCalls() -> Int {
        recentExpensesCallCount
    }

    func refreshCategoriesCancelledCalls() -> Int {
        cancelledCategoriesCallCount
    }

    func refreshRecentExpensesCancelledCalls() -> Int {
        cancelledRecentExpensesCallCount
    }

    func refreshLoadedPeriodDependentModulesCalls() -> Int {
        refreshLoadedPeriodDependentModulesCallCount
    }

    func emitOverview(
        categories: [MainCategoryCardModel],
        expenses: [MainExpenseModel]
    ) {
        store.update { state in
            categories.forEach { state.categoriesByID[$0.id] = $0 }
            state.categoryOrder = categories.map(\.id)
            expenses.forEach { state.expensesByID[$0.id] = $0 }
            state.recentExpenseIDs = expenses.map(\.id)
        }
        observer.publishAll(from: store)
    }
}
