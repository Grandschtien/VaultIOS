import XCTest
@testable import Vault

@MainActor
final class ExpesiesListInteractorTests: XCTestCase {
    func testFetchDataHappyPathBuildsLoadedState() async {
        let presenter = ExpesiesListPresenterSpy()
        let sut = makeSut(
            presenter: presenter,
            expensesProvider: ExpesiesListExpensesProviderStub(
                results: [
                    .success(
                        .init(
                            expenses: [makeExpense(id: "expense-1", time: 1_700_000_000)],
                            nextCursor: "cursor-1",
                            hasMore: true
                        )
                    )
                ]
            ),
            categoriesProvider: ExpesiesListCategoriesProviderStub(
                result: .success(
                    [
                        .init(
                            id: "cat-1",
                            name: "Food",
                            icon: "🍴",
                            color: "light_orange"
                        )
                    ]
                )
            )
        )

        await sut.fetchData()

        guard let first = presenter.presentedData.first,
              let last = presenter.presentedData.last
        else {
            return XCTFail("Expected presenter updates")
        }

        assertStatus(first.loadingState, is: .loading)
        assertStatus(last.loadingState, is: .loaded)
        XCTAssertEqual(last.categories.count, 1)
        XCTAssertEqual(last.expenseGroups.count, 1)
        XCTAssertEqual(last.expenseGroups[0].expenses.count, 1)
        XCTAssertTrue(last.hasMore)
    }
}

extension ExpesiesListInteractorTests {
    func testFetchDataFailureBuildsFailedState() async {
        let presenter = ExpesiesListPresenterSpy()
        let router = ExpesiesListRouterSpy()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            expensesProvider: ExpesiesListExpensesProviderStub(
                results: [.failure(StubError.any)]
            ),
            categoriesProvider: ExpesiesListCategoriesProviderStub(
                result: .success([])
            )
        )

        await sut.fetchData()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        assertStatus(last.loadingState, is: .failed)
        XCTAssertTrue(last.expenseGroups.isEmpty)
        XCTAssertFalse(last.isLoadingNextPage)
        XCTAssertTrue(router.presentedErrors.isEmpty)
    }
}

extension ExpesiesListInteractorTests {
    func testHandleLoadNextPageAppendsExpenses() async {
        let presenter = ExpesiesListPresenterSpy()
        let expensesProvider = ExpesiesListExpensesProviderStub(
            results: [
                .success(
                    .init(
                        expenses: [makeExpense(id: "expense-1", time: 1_700_000_100)],
                        nextCursor: "cursor-1",
                        hasMore: true
                    )
                ),
                .success(
                    .init(
                        expenses: [makeExpense(id: "expense-2", time: 1_700_000_000)],
                        nextCursor: nil,
                        hasMore: false
                    )
                )
            ]
        )
        let sut = makeSut(
            presenter: presenter,
            expensesProvider: expensesProvider,
            categoriesProvider: ExpesiesListCategoriesProviderStub(
                result: .success([])
            )
        )

        await sut.fetchData()
        await sut.handleLoadNextPage()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        let requestedPages = await expensesProvider.requestedPages()

        assertStatus(last.loadingState, is: .loaded)
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).count, 2)
        XCTAssertFalse(last.hasMore)
        XCTAssertEqual(
            requestedPages,
            [
                .init(cursor: nil, limit: 20),
                .init(cursor: "cursor-1", limit: 20)
            ]
        )
    }
}

extension ExpesiesListInteractorTests {
    func testHandleLoadNextPageWhenHasNoMoreDoesNothing() async {
        let presenter = ExpesiesListPresenterSpy()
        let expensesProvider = ExpesiesListExpensesProviderStub(
            results: [
                .success(
                    .init(
                        expenses: [makeExpense(id: "expense-1", time: 1_700_000_000)],
                        nextCursor: nil,
                        hasMore: false
                    )
                )
            ]
        )
        let sut = makeSut(
            presenter: presenter,
            expensesProvider: expensesProvider,
            categoriesProvider: ExpesiesListCategoriesProviderStub(
                result: .success([])
            )
        )

        await sut.fetchData()
        await sut.handleLoadNextPage()

        let requestedPages = await expensesProvider.requestedPages()
        XCTAssertEqual(requestedPages.count, 1)
    }
}

extension ExpesiesListInteractorTests {
    func testHandleLoadNextPageFailureKeepsExistingDataAndShowsToast() async {
        let presenter = ExpesiesListPresenterSpy()
        let router = ExpesiesListRouterSpy()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            expensesProvider: ExpesiesListExpensesProviderStub(
                results: [
                    .success(
                        .init(
                            expenses: [makeExpense(id: "expense-1", time: 1_700_000_000)],
                            nextCursor: "cursor-1",
                            hasMore: true
                        )
                    ),
                    .failure(StubError.any)
                ]
            ),
            categoriesProvider: ExpesiesListCategoriesProviderStub(
                result: .success([])
            )
        )

        await sut.fetchData()
        await sut.handleLoadNextPage()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        assertStatus(last.loadingState, is: .loaded)
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).count, 1)
        XCTAssertFalse(last.isLoadingNextPage)
        XCTAssertTrue(last.hasMore)
        XCTAssertEqual(router.presentedErrors, [L10n.mainOverviewError])
    }
}

extension ExpesiesListInteractorTests {
    func testHandleTapRetryAfterFailureLoadsDataAgain() async {
        let presenter = ExpesiesListPresenterSpy()
        let expensesProvider = ExpesiesListExpensesProviderStub(
            results: [
                .failure(StubError.any),
                .success(
                    .init(
                        expenses: [makeExpense(id: "expense-1", time: 1_700_000_000)],
                        nextCursor: nil,
                        hasMore: false
                    )
                )
            ]
        )
        let sut = makeSut(
            presenter: presenter,
            expensesProvider: expensesProvider,
            categoriesProvider: ExpesiesListCategoriesProviderStub(result: .success([]))
        )

        await sut.fetchData()
        await sut.handleTapRetry()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        assertStatus(last.loadingState, is: .loaded)
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).count, 1)
        XCTAssertEqual(await expensesProvider.requestedPages().count, 2)
    }
}

private extension ExpesiesListInteractorTests {
    enum StatusCase {
        case idle
        case loading
        case loaded
        case failed
    }

    enum StubError: Error {
        case any
    }

    func makeSut(
        presenter: ExpesiesListPresentationLogic,
        router: ExpesiesListRoutingLogic = ExpesiesListRouterSpy(),
        expensesProvider: ExpesiesListExpensesProviding,
        categoriesProvider: ExpesiesListCategoriesProviding
    ) -> ExpesiesListInteractor {
        ExpesiesListInteractor(
            presenter: presenter,
            router: router,
            expensesProvider: expensesProvider,
            categoriesProvider: categoriesProvider,
            pager: Pager(),
            expenseGrouping: MainExpenseDateGrouping()
        )
    }

    func makeExpense(id: String, time: TimeInterval) -> MainExpenseModel {
        MainExpenseModel(
            id: id,
            title: "Coffee \(id)",
            description: "Morning",
            amount: 4.5,
            currency: "USD",
            category: "cat-1",
            timeOfAdd: Date(timeIntervalSince1970: time)
        )
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
private final class ExpesiesListPresenterSpy: ExpesiesListPresentationLogic, @unchecked Sendable {
    private(set) var presentedData: [ExpesiesListFetchData] = []

    func presentFetchedData(_ data: ExpesiesListFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class ExpesiesListRouterSpy: ExpesiesListRoutingLogic, @unchecked Sendable {
    private(set) var presentedErrors: [String] = []

    func presentError(with text: String) {
        presentedErrors.append(text)
    }
}

private actor ExpesiesListExpensesProviderStub: ExpesiesListExpensesProviding {
    private let results: [Result<ExpesiesListExpensesPage, Error>]
    private var fetchCallsCount: Int = .zero
    private var requestedParameters: [ExpesiesRequestedPage] = []

    init(results: [Result<ExpesiesListExpensesPage, Error>]) {
        self.results = results
    }

    func fetchExpensesPage(cursor: String?, limit: Int) async throws -> ExpesiesListExpensesPage {
        requestedParameters.append(.init(cursor: cursor, limit: limit))
        let index = min(fetchCallsCount, max(results.count - 1, .zero))
        let result = results[index]
        fetchCallsCount += 1
        return try result.get()
    }

    func requestedPages() -> [ExpesiesRequestedPage] {
        requestedParameters
    }
}

private actor ExpesiesListCategoriesProviderStub: ExpesiesListCategoriesProviding {
    private let result: Result<[MainCategoryModel], Error>

    init(result: Result<[MainCategoryModel], Error>) {
        self.result = result
    }

    func fetchCategories() async throws -> [MainCategoryModel] {
        try result.get()
    }
}

private struct ExpesiesRequestedPage: Equatable {
    let cursor: String?
    let limit: Int
}
