import XCTest
@testable import Vault

@MainActor
final class MainInteractorTests: XCTestCase {
    func testFetchDataHappyPathLoadsAllSections() async {
        let presenter = MainPresenterSpy()
        let router = MainRouterSpy()

        let summaryProvider = MainSummaryProviderStub(result: .success(
            .init(totalAmount: 2450.8, currency: "USD", changePercent: 12)
        ))
        let categoriesProvider = MainCategoriesProviderStub(result: .success([
            .init(
                id: "1",
                name: "Food",
                icon: "🍴",
                color: "light_orange",
                amount: 10,
                currency: "USD"
            )
        ]))
        let expensesProvider = MainExpensesProviderStub(result: .success([
            .init(
                id: "1",
                title: "Coffee",
                description: "Morning",
                amount: 4.5,
                currency: "USD",
                category: "1",
                timeOfAdd: Date(timeIntervalSince1970: 100)
            )
        ]))

        let sut = makeSut(
            presenter: presenter,
            router: router,
            summaryProvider: summaryProvider,
            categoriesProvider: categoriesProvider,
            expensesProvider: expensesProvider
        )

        await sut.fetchData()

        guard let first = presenter.presentedData.first,
              let last = presenter.presentedData.last
        else {
            return XCTFail("Expected presenter updates")
        }

        assertStatus(first.summaryState, is: .loading)
        assertStatus(first.categoriesState, is: .loading)
        assertStatus(first.expensesState, is: .loading)

        assertStatus(last.summaryState, is: .loaded)
        assertStatus(last.categoriesState, is: .loaded)
        assertStatus(last.expensesState, is: .loaded)
        XCTAssertEqual(last.categories.count, 1)
        XCTAssertEqual(last.expenseGroups.count, 1)
    }
}

extension MainInteractorTests {
    func testFetchDataWhenCategoriesFailKeepsOtherSectionsLoaded() async {
        let presenter = MainPresenterSpy()

        let summaryProvider = MainSummaryProviderStub(result: .success(
            .init(totalAmount: 2450.8, currency: "USD", changePercent: 12)
        ))
        let categoriesProvider = MainCategoriesProviderStub(result: .failure(StubError.any))
        let expensesProvider = MainExpensesProviderStub(result: .success([
            .init(
                id: "1",
                title: "Coffee",
                description: "Morning",
                amount: 4.5,
                currency: "USD",
                category: "1",
                timeOfAdd: Date(timeIntervalSince1970: 100)
            )
        ]))

        let sut = makeSut(
            presenter: presenter,
            router: MainRouterSpy(),
            summaryProvider: summaryProvider,
            categoriesProvider: categoriesProvider,
            expensesProvider: expensesProvider
        )

        await sut.fetchData()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        assertStatus(last.summaryState, is: .loaded)
        assertStatus(last.expensesState, is: .loaded)

        if case .failed = last.categoriesState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected categories failed state")
        }
    }
}

extension MainInteractorTests {
    func testFetchDataStaggeredCompletionsPublishPartialUpdates() async {
        let presenter = MainPresenterSpy()

        let summaryProvider = MainSummaryProviderStub(
            result: .success(.init(totalAmount: 2450.8, currency: "USD", changePercent: 12)),
            delayNanoseconds: 40_000_000
        )
        let categoriesProvider = MainCategoriesProviderStub(
            result: .success([]),
            delayNanoseconds: 200_000_000
        )
        let expensesProvider = MainExpensesProviderStub(
            result: .success([]),
            delayNanoseconds: 250_000_000
        )

        let sut = makeSut(
            presenter: presenter,
            router: MainRouterSpy(),
            summaryProvider: summaryProvider,
            categoriesProvider: categoriesProvider,
            expensesProvider: expensesProvider
        )

        let task = Task { await sut.fetchData() }
        try? await Task.sleep(nanoseconds: 120_000_000)

        let hasPartialState = presenter.presentedData.contains { data in
            isStatus(data.summaryState, .loaded)
                && isStatus(data.categoriesState, .loading)
                && isStatus(data.expensesState, .loading)
        }

        XCTAssertTrue(hasPartialState)

        _ = await task.value
    }
}

extension MainInteractorTests {
    func testFetchDataEmptyPayloadBuildsEmptyGroups() async {
        let presenter = MainPresenterSpy()

        let sut = makeSut(
            presenter: presenter,
            router: MainRouterSpy(),
            summaryProvider: MainSummaryProviderStub(result: .success(
                .init(totalAmount: 0, currency: "USD", changePercent: 0)
            )),
            categoriesProvider: MainCategoriesProviderStub(result: .success([])),
            expensesProvider: MainExpensesProviderStub(result: .success([]))
        )

        await sut.fetchData()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        assertStatus(last.categoriesState, is: .loaded)
        assertStatus(last.expensesState, is: .loaded)
        XCTAssertTrue(last.categories.isEmpty)
        XCTAssertTrue(last.expenseGroups.isEmpty)
    }
}

extension MainInteractorTests {
    func testHandleTapRetryCategoriesReloadsOnlyCategoriesSection() async {
        let presenter = MainPresenterSpy()

        let summaryProvider = MainSummaryProviderStub(
            result: .success(.init(totalAmount: 2450.8, currency: "USD", changePercent: 12))
        )
        let categoriesProvider = MainCategoriesProviderStub(results: [
            .failure(StubError.any),
            .success([
                .init(
                    id: "1",
                    name: "Food",
                    icon: "🍴",
                    color: "light_orange",
                    amount: 10,
                    currency: "USD"
                )
            ])
        ])
        let expensesProvider = MainExpensesProviderStub(result: .success([]))

        let sut = makeSut(
            presenter: presenter,
            router: MainRouterSpy(),
            summaryProvider: summaryProvider,
            categoriesProvider: categoriesProvider,
            expensesProvider: expensesProvider
        )

        await sut.fetchData()
        await sut.handleTapRetryCategories()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        assertStatus(last.summaryState, is: .loaded)
        assertStatus(last.categoriesState, is: .loaded)
        assertStatus(last.expensesState, is: .loaded)
        XCTAssertEqual(last.categories.count, 1)

        let hasCategoriesOnlyLoadingUpdate = presenter.presentedData.contains { data in
            isStatus(data.summaryState, .loaded)
                && isStatus(data.categoriesState, .loading)
                && isStatus(data.expensesState, .loaded)
        }

        XCTAssertTrue(hasCategoriesOnlyLoadingUpdate)
        let summaryCallsCount = await summaryProvider.callsCount()
        let categoriesCallsCount = await categoriesProvider.callsCount()
        let expensesCallsCount = await expensesProvider.callsCount()
        XCTAssertEqual(summaryCallsCount, 1)
        XCTAssertEqual(categoriesCallsCount, 2)
        XCTAssertEqual(expensesCallsCount, 1)
    }
}

extension MainInteractorTests {
    func testHandleTapRetrySummaryReloadsOnlySummarySection() async {
        let presenter = MainPresenterSpy()

        let summaryProvider = MainSummaryProviderStub(results: [
            .failure(StubError.any),
            .success(.init(totalAmount: 2450.8, currency: "USD", changePercent: 12))
        ])
        let categoriesProvider = MainCategoriesProviderStub(result: .success([]))
        let expensesProvider = MainExpensesProviderStub(result: .success([]))

        let sut = makeSut(
            presenter: presenter,
            router: MainRouterSpy(),
            summaryProvider: summaryProvider,
            categoriesProvider: categoriesProvider,
            expensesProvider: expensesProvider
        )

        await sut.fetchData()
        await sut.handleTapRetrySummary()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        assertStatus(last.summaryState, is: .loaded)
        assertStatus(last.categoriesState, is: .loaded)
        assertStatus(last.expensesState, is: .loaded)
        let summaryCallsCount = await summaryProvider.callsCount()
        let categoriesCallsCount = await categoriesProvider.callsCount()
        let expensesCallsCount = await expensesProvider.callsCount()
        XCTAssertEqual(summaryCallsCount, 2)
        XCTAssertEqual(categoriesCallsCount, 1)
        XCTAssertEqual(expensesCallsCount, 1)
    }
}

extension MainInteractorTests {
    func testHandleTapRetryExpensesReloadsOnlyExpensesSection() async {
        let presenter = MainPresenterSpy()

        let summaryProvider = MainSummaryProviderStub(result: .success(
            .init(totalAmount: 2450.8, currency: "USD", changePercent: 12)
        ))
        let categoriesProvider = MainCategoriesProviderStub(result: .success([]))
        let expensesProvider = MainExpensesProviderStub(results: [
            .failure(StubError.any),
            .success([
                .init(
                    id: "1",
                    title: "Coffee",
                    description: "Morning",
                    amount: 4.5,
                    currency: "USD",
                    category: "1",
                    timeOfAdd: Date(timeIntervalSince1970: 100)
                )
            ])
        ])

        let sut = makeSut(
            presenter: presenter,
            router: MainRouterSpy(),
            summaryProvider: summaryProvider,
            categoriesProvider: categoriesProvider,
            expensesProvider: expensesProvider
        )

        await sut.fetchData()
        await sut.handleTapRetryExpenses()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        assertStatus(last.summaryState, is: .loaded)
        assertStatus(last.categoriesState, is: .loaded)
        assertStatus(last.expensesState, is: .loaded)
        XCTAssertEqual(last.expenseGroups.count, 1)
        let summaryCallsCount = await summaryProvider.callsCount()
        let categoriesCallsCount = await categoriesProvider.callsCount()
        let expensesCallsCount = await expensesProvider.callsCount()
        XCTAssertEqual(summaryCallsCount, 1)
        XCTAssertEqual(categoriesCallsCount, 1)
        XCTAssertEqual(expensesCallsCount, 2)
    }
}

extension MainInteractorTests {
    func testSeeAllHandlersOnlyCallRouter() async {
        let presenter = MainPresenterSpy()
        let router = MainRouterSpy()

        let sut = makeSut(
            presenter: presenter,
            router: router,
            summaryProvider: MainSummaryProviderStub(result: .success(
                .init(totalAmount: 0, currency: "USD", changePercent: 0)
            )),
            categoriesProvider: MainCategoriesProviderStub(result: .success([])),
            expensesProvider: MainExpensesProviderStub(result: .success([]))
        )

        await sut.fetchData()
        let updatesCount = presenter.presentedData.count

        await sut.handleTapSeeAllCategories()
        await sut.handleTapSeeAllExpenses()

        XCTAssertEqual(router.openCategoriesCount, 1)
        XCTAssertEqual(router.openExpensesCount, 1)
        XCTAssertEqual(presenter.presentedData.count, updatesCount)
    }
}

private extension MainInteractorTests {
    func makeSut(
        presenter: MainPresentationLogic,
        router: MainRoutingLogic,
        summaryProvider: MainSummaryProviding,
        categoriesProvider: MainCategoriesProviding,
        expensesProvider: MainExpensesProviding
    ) -> MainInteractor {
        MainInteractor(
            presenter: presenter,
            router: router,
            summaryProvider: summaryProvider,
            categoriesProvider: categoriesProvider,
            expensesProvider: expensesProvider,
            expenseGrouping: MainExpenseDateGrouping()
        )
    }

    enum StubError: Error {
        case any
    }

    enum StatusCase {
        case idle
        case loading
        case loaded
        case failed
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

    func openAllCategories() {
        openCategoriesCount += 1
    }

    func openAllExpenses() {
        openExpensesCount += 1
    }
}

private actor MainSummaryProviderStub: MainSummaryProviding {
    let results: [Result<MainSummaryModel, Error>]
    let delayNanoseconds: UInt64
    private var fetchCallsCount: Int = .zero

    init(result: Result<MainSummaryModel, Error>, delayNanoseconds: UInt64 = .zero) {
        self.results = [result]
        self.delayNanoseconds = delayNanoseconds
    }

    init(results: [Result<MainSummaryModel, Error>], delayNanoseconds: UInt64 = .zero) {
        self.results = results
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchSummary() async throws -> MainSummaryModel {
        if delayNanoseconds > .zero {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }

        let currentResult = resultForCurrentCall()
        fetchCallsCount += 1
        return try currentResult.get()
    }

    func callsCount() -> Int {
        fetchCallsCount
    }

    private func resultForCurrentCall() -> Result<MainSummaryModel, Error> {
        let index = min(fetchCallsCount, max(results.count - 1, .zero))
        return results[index]
    }
}

private actor MainCategoriesProviderStub: MainCategoriesProviding {
    let results: [Result<[MainCategoryCardModel], Error>]
    let delayNanoseconds: UInt64
    private var fetchCallsCount: Int = .zero

    init(result: Result<[MainCategoryCardModel], Error>, delayNanoseconds: UInt64 = .zero) {
        self.results = [result]
        self.delayNanoseconds = delayNanoseconds
    }

    init(results: [Result<[MainCategoryCardModel], Error>], delayNanoseconds: UInt64 = .zero) {
        self.results = results
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchCategories() async throws -> [MainCategoryCardModel] {
        if delayNanoseconds > .zero {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }

        let currentResult = resultForCurrentCall()
        fetchCallsCount += 1
        return try currentResult.get()
    }

    func callsCount() -> Int {
        fetchCallsCount
    }

    private func resultForCurrentCall() -> Result<[MainCategoryCardModel], Error> {
        let index = min(fetchCallsCount, max(results.count - 1, .zero))
        return results[index]
    }
}

private actor MainExpensesProviderStub: MainExpensesProviding {
    let results: [Result<[MainExpenseModel], Error>]
    let delayNanoseconds: UInt64
    private var fetchCallsCount: Int = .zero

    init(result: Result<[MainExpenseModel], Error>, delayNanoseconds: UInt64 = .zero) {
        self.results = [result]
        self.delayNanoseconds = delayNanoseconds
    }

    init(results: [Result<[MainExpenseModel], Error>], delayNanoseconds: UInt64 = .zero) {
        self.results = results
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchExpenses() async throws -> [MainExpenseModel] {
        if delayNanoseconds > .zero {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }

        let currentResult = resultForCurrentCall()
        fetchCallsCount += 1
        return try currentResult.get()
    }

    func callsCount() -> Int {
        fetchCallsCount
    }

    private func resultForCurrentCall() -> Result<[MainExpenseModel], Error> {
        let index = min(fetchCallsCount, max(results.count - 1, .zero))
        return results[index]
    }
}
