import XCTest
@testable import Vault

@MainActor
final class ExpesiesListInteractorTests: XCTestCase {
    func testFetchDataBuildsLoadedState() async {
        let presenter = ExpesiesListPresenterSpy()
        let repository = ExpesiesListRepositoryStub(
            firstPageResults: [
                .success(
                    .init(
                        expenses: [makeExpense(id: "expense-1", time: 1_700_000_000)],
                        hasMore: true
                    )
                )
            ],
            nextPageResults: []
        )
        let sut = makeSut(
            presenter: presenter,
            router: ExpesiesListRouterSpy(),
            repository: repository,
            observer: repository.observer
        )

        await sut.fetchData()
        await waitForUpdates()

        guard let first = presenter.presentedData.first,
              let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter updates")
        }

        assertStatus(first.loadingState, is: .loading)
        assertStatus(last.loadingState, is: .loaded)
        XCTAssertEqual(last.categories.count, 1)
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).count, 1)
        XCTAssertTrue(last.hasMore)
    }
}

extension ExpesiesListInteractorTests {
    func testHandleLoadNextPageAppendsExpenses() async {
        let presenter = ExpesiesListPresenterSpy()
        let repository = ExpesiesListRepositoryStub(
            firstPageResults: [
                .success(
                    .init(
                        expenses: [makeExpense(id: "expense-1", time: 1_700_000_100)],
                        hasMore: true
                    )
                )
            ],
            nextPageResults: [
                .success(
                    .init(
                        expenses: [makeExpense(id: "expense-2", time: 1_700_000_000)],
                        hasMore: false
                    )
                )
            ]
        )
        let sut = makeSut(
            presenter: presenter,
            router: ExpesiesListRouterSpy(),
            repository: repository,
            observer: repository.observer
        )

        await sut.fetchData()
        await sut.handleLoadNextPage()
        await waitForUpdates()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        assertStatus(last.loadingState, is: .loaded)
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).count, 2)
        XCTAssertFalse(last.hasMore)
    }
}

extension ExpesiesListInteractorTests {
    func testHandleLoadNextPageFailureKeepsExistingDataAndShowsToast() async {
        let presenter = ExpesiesListPresenterSpy()
        let router = ExpesiesListRouterSpy()
        let repository = ExpesiesListRepositoryStub(
            firstPageResults: [
                .success(
                    .init(
                        expenses: [makeExpense(id: "expense-1", time: 1_700_000_100)],
                        hasMore: true
                    )
                )
            ],
            nextPageResults: [.failure(StubError.any)]
        )
        let sut = makeSut(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: repository.observer
        )

        await sut.fetchData()
        await sut.handleLoadNextPage()
        await waitForUpdates()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        assertStatus(last.loadingState, is: .loaded)
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).count, 1)
        XCTAssertTrue(last.hasMore)
        XCTAssertEqual(router.presentedErrors, [L10n.mainOverviewError])
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
        router: ExpesiesListRoutingLogic,
        repository: MainFlowDomainRepositoryProtocol,
        observer: MainFlowDomainObserverProtocol
    ) -> ExpesiesListInteractor {
        ExpesiesListInteractor(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer
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

private actor ExpesiesListRepositoryStub: MainFlowDomainRepositoryProtocol {
    nonisolated let observer: MainFlowDomainObserverProtocol

    private let store: MainFlowDomainStoreProtocol
    private let firstPageResults: [Result<PagePayload, Error>]
    private let nextPageResults: [Result<PagePayload, Error>]
    private var firstPageCallCount: Int = .zero
    private var nextPageCallCount: Int = .zero

    init(
        firstPageResults: [Result<PagePayload, Error>],
        nextPageResults: [Result<PagePayload, Error>]
    ) {
        let store = MainFlowDomainStore()
        self.store = store
        self.observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        self.firstPageResults = firstPageResults
        self.nextPageResults = nextPageResults
    }

    func refreshMainFlow() async throws {}

    func refreshCategories() async throws {
        let category = MainCategoryCardModel(
            id: "cat-1",
            name: "Food",
            icon: "🍴",
            color: "light_orange",
            amount: 10,
            currency: "USD"
        )

        store.update { state in
            state.categoriesByID[category.id] = category
            state.categoryOrder = [category.id]
        }
        observer.publishAll(from: store)
    }

    func refreshRecentExpenses() async throws {}
    func refreshCategoryFirstPage(id: String, fromDate: Date?) async throws {}
    func handleCurrencyDidChange(_ payload: ProfileCurrencyDidChangePayload) async {}

    func refreshExpensesFirstPage() async throws {
        let index = min(firstPageCallCount, max(firstPageResults.count - 1, .zero))
        let payload = try firstPageResults[index].get()
        firstPageCallCount += 1

        store.update { state in
            payload.expenses.forEach { state.expensesByID[$0.id] = $0 }
            state.expensesListExpenseIDs = payload.expenses.map(\.id)
            state.expensesListPagination = .init(
                nextCursor: payload.hasMore ? "cursor-1" : nil,
                hasMore: payload.hasMore,
                isLoaded: true
            )
        }
        observer.publishAll(from: store)
    }

    func loadNextCategoryPage(id: String) async throws {}

    func loadNextExpensesPage() async throws {
        let index = min(nextPageCallCount, max(nextPageResults.count - 1, .zero))
        let payload = try nextPageResults[index].get()
        nextPageCallCount += 1

        store.update { state in
            payload.expenses.forEach { state.expensesByID[$0.id] = $0 }
            state.expensesListExpenseIDs += payload.expenses.map(\.id)
            state.expensesListPagination = .init(
                nextCursor: payload.hasMore ? "cursor-\(nextPageCallCount)" : nil,
                hasMore: payload.hasMore,
                isLoaded: true
            )
        }
        observer.publishAll(from: store)
    }

    func addExpense(_ request: ExpensesCreateRequestDTO) async throws {}
    func deleteExpense(id: String) async throws {}
    func addCategory(_ request: CategoryCreateRequestDTO) async throws {}
    func deleteCategory(id: String) async throws {}
    func clearSession() async {}
}

private extension ExpesiesListRepositoryStub {
    struct PagePayload {
        let expenses: [MainExpenseModel]
        let hasMore: Bool
    }
}
