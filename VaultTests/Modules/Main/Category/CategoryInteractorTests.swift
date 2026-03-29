import XCTest
@testable import Vault

@MainActor
final class CategoryInteractorTests: XCTestCase {
    func testFetchDataHappyPathBuildsLoadedState() async {
        let presenter = CategoryPresenterSpy()
        let sut = makeSut(
            presenter: presenter,
            summaryProvider: CategorySummaryProviderStub(
                results: [
                    .success(
                        .init(
                            id: "cat-1",
                            name: "Food",
                            icon: "🍴",
                            color: "light_orange",
                            amount: 10,
                            currency: "USD"
                        )
                    )
                ]
            ),
            expensesProvider: CategoryExpensesProviderStub(
                pageResults: [
                    .success(
                        .init(
                            expenses: [makeExpense(id: "exp-1", time: 100)],
                            nextCursor: nil,
                            hasMore: false
                        )
                    )
                ],
                deleteResult: .success(())
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
        XCTAssertEqual(last.navigationTitle, "Food")
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).count, 1)
    }
}

extension CategoryInteractorTests {
    func testFetchDataFailureBuildsFailedState() async {
        let presenter = CategoryPresenterSpy()
        let sut = makeSut(
            presenter: presenter,
            summaryProvider: CategorySummaryProviderStub(
                results: [.failure(StubError.any)]
            ),
            expensesProvider: CategoryExpensesProviderStub(
                pageResults: [.success(.init(expenses: [], nextCursor: nil, hasMore: false))],
                deleteResult: .success(())
            )
        )

        await sut.fetchData()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        assertStatus(last.loadingState, is: .failed)
    }
}

extension CategoryInteractorTests {
    func testHandleLoadNextPageAppendsExpenses() async {
        let presenter = CategoryPresenterSpy()
        let expensesProvider = CategoryExpensesProviderStub(
            pageResults: [
                .success(
                    .init(
                        expenses: [makeExpense(id: "exp-1", time: 200)],
                        nextCursor: "cursor-1",
                        hasMore: true
                    )
                ),
                .success(
                    .init(
                        expenses: [makeExpense(id: "exp-2", time: 100)],
                        nextCursor: nil,
                        hasMore: false
                    )
                )
            ],
            deleteResult: .success(())
        )
        let sut = makeSut(
            presenter: presenter,
            summaryProvider: CategorySummaryProviderStub(
                results: [.success(makeCategory(amount: 10))]
            ),
            expensesProvider: expensesProvider
        )

        await sut.fetchData()
        await sut.handleLoadNextPage()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        assertStatus(last.loadingState, is: .loaded)
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).count, 2)
        XCTAssertFalse(last.hasMore)

        XCTAssertEqual(
            await expensesProvider.requestedPages(),
            [
                .init(categoryID: "cat-1", cursor: nil, limit: 20),
                .init(categoryID: "cat-1", cursor: "cursor-1", limit: 20)
            ]
        )
    }
}

extension CategoryInteractorTests {
    func testHandleDeleteExpenseSuccessRemovesExpenseAndRefreshesSummary() async {
        let presenter = CategoryPresenterSpy()
        let summaryProvider = CategorySummaryProviderStub(
            results: [
                .success(makeCategory(amount: 10)),
                .success(makeCategory(amount: 0))
            ]
        )
        let sut = makeSut(
            presenter: presenter,
            summaryProvider: summaryProvider,
            expensesProvider: CategoryExpensesProviderStub(
                pageResults: [
                    .success(
                        .init(
                            expenses: [makeExpense(id: "exp-1", time: 100)],
                            nextCursor: nil,
                            hasMore: false
                        )
                    )
                ],
                deleteResult: .success(())
            )
        )

        await sut.fetchData()
        await sut.handleDeleteExpense(id: "exp-1")

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        XCTAssertTrue(last.expenseGroups.isEmpty)
        XCTAssertTrue(last.deletingExpenseIDs.isEmpty)
        XCTAssertEqual(last.category?.amount, 0)
        XCTAssertEqual(await summaryProvider.callsCount(), 2)
    }
}

extension CategoryInteractorTests {
    func testHandleDeleteExpenseFailureKeepsExpenseAndClearsDeletingState() async {
        let presenter = CategoryPresenterSpy()
        let router = CategoryRouterSpy()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            summaryProvider: CategorySummaryProviderStub(
                results: [.success(makeCategory(amount: 10))]
            ),
            expensesProvider: CategoryExpensesProviderStub(
                pageResults: [
                    .success(
                        .init(
                            expenses: [makeExpense(id: "exp-1", time: 100)],
                            nextCursor: nil,
                            hasMore: false
                        )
                    )
                ],
                deleteResult: .failure(StubError.any)
            )
        )

        await sut.fetchData()
        await sut.handleDeleteExpense(id: "exp-1")

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).count, 1)
        XCTAssertTrue(last.deletingExpenseIDs.isEmpty)
        XCTAssertEqual(router.presentedErrors, [L10n.mainOverviewError])
    }
}

extension CategoryInteractorTests {
    func testHandleTapEditButtonRoutesToEditScreen() async {
        let router = CategoryRouterSpy()
        let sut = makeSut(
            presenter: CategoryPresenterSpy(),
            router: router,
            summaryProvider: CategorySummaryProviderStub(
                results: [.success(makeCategory(amount: 10))]
            ),
            expensesProvider: CategoryExpensesProviderStub(
                pageResults: [.success(.init(expenses: [], nextCursor: nil, hasMore: false))],
                deleteResult: .success(())
            )
        )

        await sut.handleTapEditButton()

        XCTAssertEqual(router.openEditCalls.count, 1)
        XCTAssertEqual(router.openEditCalls.first?.id, "cat-1")
        XCTAssertEqual(router.openEditCalls.first?.name, "Food")
    }
}

private extension CategoryInteractorTests {
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
        presenter: CategoryPresentationLogic,
        router: CategoryRoutingLogic = CategoryRouterSpy(),
        summaryProvider: CategorySummaryProviding,
        expensesProvider: CategoryExpensesProviding
    ) -> CategoryInteractor {
        CategoryInteractor(
            categoryID: "cat-1",
            categoryName: "Food",
            presenter: presenter,
            router: router,
            summaryProvider: summaryProvider,
            expensesProvider: expensesProvider,
            pager: Pager(),
            expenseGrouping: MainExpenseDateGrouping()
        )
    }

    func makeExpense(id: String, time: TimeInterval) -> MainExpenseModel {
        MainExpenseModel(
            id: id,
            title: "Coffee",
            description: "Morning",
            amount: 4.5,
            currency: "USD",
            category: "cat-1",
            timeOfAdd: Date(timeIntervalSince1970: time)
        )
    }

    func makeCategory(amount: Double) -> MainCategoryCardModel {
        MainCategoryCardModel(
            id: "cat-1",
            name: "Food",
            icon: "🍴",
            color: "light_orange",
            amount: amount,
            currency: "USD"
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
private final class CategoryPresenterSpy: CategoryPresentationLogic, @unchecked Sendable {
    private(set) var presentedData: [CategoryFetchData] = []

    func presentFetchedData(_ data: CategoryFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class CategoryRouterSpy: CategoryRoutingLogic, @unchecked Sendable {
    private(set) var openEditCalls: [(id: String, name: String)] = []
    private(set) var presentedErrors: [String] = []

    func openCategoryEdit(id: String, name: String) {
        openEditCalls.append((id, name))
    }

    func presentError(with text: String) {
        presentedErrors.append(text)
    }
}

private actor CategorySummaryProviderStub: CategorySummaryProviding {
    private let results: [Result<MainCategoryCardModel, Error>]
    private var fetchCallsCount: Int = .zero

    init(results: [Result<MainCategoryCardModel, Error>]) {
        self.results = results
    }

    func fetchCategory(id: String) async throws -> MainCategoryCardModel {
        let index = min(fetchCallsCount, max(results.count - 1, .zero))
        let result = results[index]
        fetchCallsCount += 1
        return try result.get()
    }

    func callsCount() -> Int {
        fetchCallsCount
    }
}

private actor CategoryExpensesProviderStub: CategoryExpensesProviding {
    private let pageResults: [Result<CategoryExpensesPage, Error>]
    private let deleteResult: Result<Void, Error>
    private var pageFetchCount: Int = .zero
    private var pageRequests: [CategoryPageRequest] = []

    init(
        pageResults: [Result<CategoryExpensesPage, Error>],
        deleteResult: Result<Void, Error>
    ) {
        self.pageResults = pageResults
        self.deleteResult = deleteResult
    }

    func fetchExpensesPage(
        categoryID: String,
        cursor: String?,
        limit: Int
    ) async throws -> CategoryExpensesPage {
        pageRequests.append(
            .init(
                categoryID: categoryID,
                cursor: cursor,
                limit: limit
            )
        )

        let index = min(pageFetchCount, max(pageResults.count - 1, .zero))
        let result = pageResults[index]
        pageFetchCount += 1
        return try result.get()
    }

    func deleteExpense(id: String) async throws {
        _ = try deleteResult.get()
    }

    func requestedPages() -> [CategoryPageRequest] {
        pageRequests
    }
}

private struct CategoryPageRequest: Equatable {
    let categoryID: String
    let cursor: String?
    let limit: Int
}
