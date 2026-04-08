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

        XCTAssertEqual(last.blockingErrorDescription, L10n.mainOverviewError)
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
        let presenter = MainPresenterSpy()
        let repository = MainRepositoryStub(
            categoriesResults: [
                .failure(StubError.any),
                .success([makeCategory(id: "cat-1", amount: 10)])
            ],
            recentExpensesResults: [.success([])]
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
        await sut.handleTapRetryCategories()
        await waitForUpdates()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        assertStatus(last.summaryState, is: .loaded)
        assertStatus(last.categoriesState, is: .loaded)
        assertStatus(last.expensesState, is: .loaded)
        XCTAssertEqual(last.categories.count, 1)
        let categoriesCalls = await repository.refreshCategoriesCalls()
        let expensesCalls = await repository.refreshRecentExpensesCalls()
        XCTAssertEqual(categoriesCalls, 2)
        XCTAssertEqual(expensesCalls, 1)
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

        XCTAssertEqual(summaryPeriodProvider.currentMonthPeriod(), expectedPeriod)
        XCTAssertEqual(await summaryProvider.recordedFetchCallsCount(), 1)
        XCTAssertEqual(await repository.refreshCategoriesCalls(), 1)
        XCTAssertEqual(await repository.refreshRecentExpensesCalls(), 1)
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
        repository: MainFlowDomainRepositoryProtocol,
        observer: MainFlowDomainObserverProtocol
    ) -> MainInteractor {
        MainInteractor(
            presenter: presenter,
            router: router,
            currencyRateProvider: currencyRateProvider,
            summaryProvider: summaryProvider,
            summaryPeriodProvider: summaryPeriodProvider,
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

    func openAllCategories() {
        openCategoriesCount += 1
    }

    func openAllExpenses() {
        openExpensesCount += 1
    }

    func openCategory(id: String, name: String) {
        openCategoryCalls.append((id, name))
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
    private var fetchCallsCount: Int = .zero

    init(result: Result<MainSummaryModel, Error>) {
        self.results = [result]
    }

    func fetchSummary() async throws -> MainSummaryModel {
        let index = min(fetchCallsCount, max(results.count - 1, .zero))
        fetchCallsCount += 1
        return try results[index].get()
    }

    func recordedFetchCallsCount() -> Int {
        fetchCallsCount
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

private final class MainSummaryPeriodServiceStub: MainSummaryPeriodServicing, @unchecked Sendable {
    private var period: MainSummaryPeriod

    init(
        period: MainSummaryPeriod = .init(
            from: Date(timeIntervalSince1970: 1),
            to: Date(timeIntervalSince1970: 2)
        )
    ) {
        self.period = period
    }

    func currentMonthPeriod() -> MainSummaryPeriod {
        period
    }

    func updatePeriod(from: Date, to: Date) {
        period = .init(from: from, to: to)
    }
}

private actor MainRepositoryStub: MainFlowDomainRepositoryProtocol {
    nonisolated let observer: MainFlowDomainObserverProtocol

    private let store: MainFlowDomainStoreProtocol
    private let categoriesResults: [Result<[MainCategoryCardModel], Error>]
    private let recentExpensesResults: [Result<[MainExpenseModel], Error>]
    private var categoriesCallCount: Int = .zero
    private var recentExpensesCallCount: Int = .zero

    init(
        categoriesResults: [Result<[MainCategoryCardModel], Error>],
        recentExpensesResults: [Result<[MainExpenseModel], Error>]
    ) {
        let store = MainFlowDomainStore()
        self.store = store
        self.observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        self.categoriesResults = categoriesResults
        self.recentExpensesResults = recentExpensesResults
    }

    func refreshMainFlow() async throws {
        try await refreshCategories()
        try await refreshRecentExpenses()
    }

    func refreshCategories() async throws {
        let index = min(categoriesCallCount, max(categoriesResults.count - 1, .zero))
        let categories = try categoriesResults[index].get()
        categoriesCallCount += 1

        store.update { state in
            categories.forEach { state.categoriesByID[$0.id] = $0 }
            state.categoryOrder = categories.map(\.id)
        }
        observer.publishAll(from: store)
    }

    func refreshRecentExpenses() async throws {
        let index = min(recentExpensesCallCount, max(recentExpensesResults.count - 1, .zero))
        let expenses = try recentExpensesResults[index].get()
        recentExpensesCallCount += 1

        store.update { state in
            expenses.forEach { state.expensesByID[$0.id] = $0 }
            state.recentExpenseIDs = expenses.map(\.id)
        }
        observer.publishAll(from: store)
    }

    func refreshCategoryFirstPage(id: String, fromDate: Date?, toDate: Date?) async throws {}
    func refreshExpensesFirstPage() async throws {}
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
