import XCTest
@testable import Vault

@MainActor
final class CategoryInteractorTests: XCTestCase {
    func testFetchDataBuildsLoadedState() async {
        let presenter = CategoryPresenterSpy()
        let repository = CategoryRepositoryStub(
            refreshResults: [
                .success(
                    .init(
                        category: makeCategory(amount: 10),
                        expenses: [makeExpense(id: "exp-1", time: 100)],
                        hasMore: false
                    )
                )
            ],
            nextPageResults: [],
            deleteResults: []
        )
        let sut = makeSut(
            presenter: presenter,
            router: CategoryRouterSpy(),
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
        XCTAssertEqual(last.navigationTitle, "Food")
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).count, 1)
    }
}

extension CategoryInteractorTests {
    func testHandleLoadNextPageAppendsExpenses() async {
        let presenter = CategoryPresenterSpy()
        let repository = CategoryRepositoryStub(
            refreshResults: [
                .success(
                    .init(
                        category: makeCategory(amount: 10),
                        expenses: [makeExpense(id: "exp-1", time: 200)],
                        hasMore: true
                    )
                )
            ],
            nextPageResults: [
                .success(
                    .init(
                        category: makeCategory(amount: 10),
                        expenses: [makeExpense(id: "exp-2", time: 100)],
                        hasMore: false
                    )
                )
            ],
            deleteResults: []
        )
        let sut = makeSut(
            presenter: presenter,
            router: CategoryRouterSpy(),
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

extension CategoryInteractorTests {
    func testHandleDeleteExpenseFailureRestoresStateAndShowsError() async {
        let presenter = CategoryPresenterSpy()
        let router = CategoryRouterSpy()
        let repository = CategoryRepositoryStub(
            refreshResults: [
                .success(
                    .init(
                        category: makeCategory(amount: 10),
                        expenses: [makeExpense(id: "exp-1", time: 100)],
                        hasMore: false
                    )
                )
            ],
            nextPageResults: [],
            deleteResults: [.failure(StubError.any)]
        )
        let sut = makeSut(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: repository.observer
        )

        await sut.fetchData()
        await sut.handleDeleteExpense(id: "exp-1")
        await waitForUpdates()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).count, 1)
        XCTAssertTrue(last.deletingExpenseIDs.isEmpty)
        XCTAssertEqual(router.presentedErrors, [L10n.mainOverviewError])
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
        router: CategoryRoutingLogic,
        repository: MainFlowDomainRepositoryProtocol,
        observer: MainFlowDomainObserverProtocol
    ) -> CategoryInteractor {
        CategoryInteractor(
            categoryID: "cat-1",
            categoryName: "Food",
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer
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

private actor CategoryRepositoryStub: MainFlowDomainRepositoryProtocol {
    nonisolated let observer: MainFlowDomainObserverProtocol

    private let store: MainFlowDomainStoreProtocol
    private let refreshResults: [Result<CategoryPayload, Error>]
    private let nextPageResults: [Result<CategoryPayload, Error>]
    private let deleteResults: [Result<Void, Error>]
    private var refreshCallCount: Int = .zero
    private var nextPageCallCount: Int = .zero
    private var deleteCallCount: Int = .zero

    init(
        refreshResults: [Result<CategoryPayload, Error>],
        nextPageResults: [Result<CategoryPayload, Error>],
        deleteResults: [Result<Void, Error>]
    ) {
        let store = MainFlowDomainStore()
        self.store = store
        self.observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        self.refreshResults = refreshResults
        self.nextPageResults = nextPageResults
        self.deleteResults = deleteResults
    }

    func refreshMainFlow() async throws {}
    func refreshCategories() async throws {}
    func refreshRecentExpenses() async throws {}

    func refreshCategoryFirstPage(id: String) async throws {
        let index = min(refreshCallCount, max(refreshResults.count - 1, .zero))
        let payload = try refreshResults[index].get()
        refreshCallCount += 1
        apply(payload: payload, replaceExpenses: true)
    }

    func refreshExpensesFirstPage() async throws {}
    func handleCurrencyDidChange(_ payload: ProfileCurrencyDidChangePayload) async {}

    func loadNextCategoryPage(id: String) async throws {
        let index = min(nextPageCallCount, max(nextPageResults.count - 1, .zero))
        let payload = try nextPageResults[index].get()
        nextPageCallCount += 1
        apply(payload: payload, replaceExpenses: false)
    }

    func loadNextExpensesPage() async throws {}
    func addExpense(_ request: ExpensesCreateRequestDTO) async throws {}

    func deleteExpense(id: String) async throws {
        let index = min(deleteCallCount, max(deleteResults.count - 1, .zero))
        let result = deleteResults[index]
        deleteCallCount += 1

        let previousState = store.snapshot()
        store.update { state in
            state.pendingDeletedExpenseIDs.insert(id)
            state.categoryExpenseIDs["cat-1"]?.removeAll { $0 == id }
        }
        observer.publishAll(from: store)

        do {
            _ = try result.get()
            store.update { state in
                state.pendingDeletedExpenseIDs.remove(id)
                state.expensesByID[id] = nil
            }
            observer.publishAll(from: store)
        } catch {
            store.replaceState(previousState)
            observer.publishAll(from: store)
            throw error
        }
    }

    func addCategory(_ request: CategoryCreateRequestDTO) async throws {}
    func deleteCategory(id: String) async throws {}
    func clearSession() async {}

    func apply(payload: CategoryPayload, replaceExpenses: Bool) {
        store.update { state in
            state.categoriesByID[payload.category.id] = payload.category
            if !state.categoryOrder.contains(payload.category.id) {
                state.categoryOrder.append(payload.category.id)
            }

            payload.expenses.forEach { state.expensesByID[$0.id] = $0 }

            if replaceExpenses {
                state.categoryExpenseIDs[payload.category.id] = payload.expenses.map(\.id)
            } else {
                state.categoryExpenseIDs[payload.category.id, default: []] += payload.expenses.map(\.id)
            }

            state.categoryPagination[payload.category.id] = .init(
                nextCursor: payload.hasMore ? "cursor" : nil,
                hasMore: payload.hasMore,
                isLoaded: true
            )
        }
        observer.publishAll(from: store)
    }
}

private extension CategoryRepositoryStub {
    struct CategoryPayload {
        let category: MainCategoryCardModel
        let expenses: [MainExpenseModel]
        let hasMore: Bool
    }
}
