import XCTest
@testable import Vault

@MainActor
final class CategoriesListInteractorTests: XCTestCase {
    func testFetchDataLoadsFreshCategories() async {
        let presenter = CategoriesListPresenterSpy()
        let repository = CategoriesListRepositoryStub(
            results: [.success([makeCategory(amount: 12.5)])]
        )
        let sut = CategoriesListInteractor(
            presenter: presenter,
            router: CategoriesListRouterSpy(),
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
    }
}

extension CategoriesListInteractorTests {
    func testFetchDataWithExistingSnapshotKeepsLoadedStateOnRefreshFailure() async {
        let presenter = CategoriesListPresenterSpy()
        let repository = CategoriesListRepositoryStub(results: [.failure(StubError.any)])
        await repository.seed(categories: [makeCategory(amount: 5)])

        let sut = CategoriesListInteractor(
            presenter: presenter,
            router: CategoriesListRouterSpy(),
            repository: repository,
            observer: repository.observer
        )

        await sut.fetchData()
        await waitForUpdates()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter updates")
        }

        assertStatus(last.loadingState, is: .loaded)
        XCTAssertEqual(last.categories.first?.amount, 5)
    }
}

extension CategoriesListInteractorTests {
    func testHandleTapCategoryRoutesToCategoryScreen() async {
        let router = CategoriesListRouterSpy()
        let repository = CategoriesListRepositoryStub(results: [.success([])])
        let sut = CategoriesListInteractor(
            presenter: CategoriesListPresenterSpy(),
            router: router,
            repository: repository,
            observer: repository.observer
        )

        await sut.handleTapCategory(id: "cat-1", name: "Food")

        XCTAssertEqual(router.openCategoryCalls.count, 1)
        XCTAssertEqual(router.openCategoryCalls.first?.id, "cat-1")
        XCTAssertEqual(router.openCategoryCalls.first?.name, "Food")
    }
}

private extension CategoriesListInteractorTests {
    enum StubError: Error {
        case any
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

    func assertStatus(_ status: LoadingStatus, is expected: LoadingStatus) {
        switch (status, expected) {
        case (.idle, .idle),
             (.loading, .loading),
             (.loaded, .loaded),
             (.failed, .failed):
            XCTAssertTrue(true)
        default:
            XCTFail("Unexpected status. got: \(status), expected: \(expected)")
        }
    }
}

@MainActor
private final class CategoriesListPresenterSpy: CategoriesListPresentationLogic {
    private(set) var presentedData: [CategoriesListFetchData] = []

    func presentFetchedData(_ data: CategoriesListFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class CategoriesListRouterSpy: CategoriesListRoutingLogic {
    private(set) var openCategoryCalls: [(id: String, name: String)] = []

    func openCategory(id: String, name: String) {
        openCategoryCalls.append((id, name))
    }
}

private actor CategoriesListRepositoryStub: MainFlowDomainRepositoryProtocol {
    nonisolated let observer: MainFlowDomainObserverProtocol

    private let store: MainFlowDomainStoreProtocol
    private let results: [Result<[MainCategoryCardModel], Error>]
    private var callCount: Int = .zero

    init(results: [Result<[MainCategoryCardModel], Error>]) {
        let store = MainFlowDomainStore()
        self.store = store
        self.observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        self.results = results
    }

    func refreshMainFlow() async throws {
        try await refreshCategories()
    }

    func refreshCategories() async throws {
        let index = min(callCount, max(results.count - 1, .zero))
        let categories = try results[index].get()
        callCount += 1

        store.update { state in
            categories.forEach { state.categoriesByID[$0.id] = $0 }
            state.categoryOrder = categories.map(\.id)
        }
        observer.publishAll(from: store)
    }

    func refreshRecentExpenses() async throws {}
    func refreshCategoryFirstPage(id: String) async throws {}
    func refreshExpensesFirstPage() async throws {}
    func loadNextCategoryPage(id: String) async throws {}
    func loadNextExpensesPage() async throws {}
    func addExpense(_ request: ExpensesCreateRequestDTO) async throws {}
    func deleteExpense(id: String) async throws {}
    func addCategory(_ request: CategoryCreateRequestDTO) async throws {}
    func deleteCategory(id: String) async throws {}
    func clearSession() async {}

    func seed(categories: [MainCategoryCardModel]) {
        store.update { state in
            categories.forEach { state.categoriesByID[$0.id] = $0 }
            state.categoryOrder = categories.map(\.id)
        }
        observer.publishAll(from: store)
    }
}
