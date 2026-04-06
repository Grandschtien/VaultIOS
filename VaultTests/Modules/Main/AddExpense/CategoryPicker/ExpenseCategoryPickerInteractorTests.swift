import XCTest
@testable import Vault

@MainActor
final class ExpenseCategoryPickerInteractorTests: XCTestCase {
    func testFetchDataLoadsCategoriesAndKeepsCurrentSelection() async {
        let presenter = ExpenseCategoryPickerPresenterSpy()
        let router = ExpenseCategoryPickerRouterSpy()
        let observer = MainFlowObserverStub()
        observer.categoriesSnapshot = .init(
            categories: [
                .init(id: "food", name: "Food", icon: "🍔", color: "green", amount: 12, currency: "USD"),
                .init(id: "car", name: "Car", icon: "🚗", color: "blue", amount: 9, currency: "USD")
            ]
        )
        let repository = MainFlowRepositorySpy()
        let output = ExpenseCategoryPickerOutputSpy()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            output: output,
            selectedCategoryID: "car"
        )

        await sut.fetchData()

        XCTAssertEqual(presenter.presentedData.last?.categories.count, 2)
        XCTAssertEqual(presenter.presentedData.last?.selectedCategoryID, "car")
    }

    func testHandleTapCategoryTogglesActiveSelection() async {
        let presenter = ExpenseCategoryPickerPresenterSpy()
        let router = ExpenseCategoryPickerRouterSpy()
        let observer = MainFlowObserverStub()
        observer.categoriesSnapshot = .init(
            categories: [
                .init(id: "food", name: "Food", icon: "🍔", color: "green", amount: 12, currency: "USD")
            ]
        )
        let repository = MainFlowRepositorySpy()
        let output = ExpenseCategoryPickerOutputSpy()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            output: output,
            selectedCategoryID: nil
        )

        await sut.fetchData()
        await sut.handleTapCategory(id: "food")
        XCTAssertEqual(presenter.presentedData.last?.selectedCategoryID, "food")

        await sut.handleTapCategory(id: "food")
        XCTAssertNil(presenter.presentedData.last?.selectedCategoryID)
    }

    func testHandleTapAddNotifiesOutputAndClosesPicker() async {
        let presenter = ExpenseCategoryPickerPresenterSpy()
        let router = ExpenseCategoryPickerRouterSpy()
        let observer = MainFlowObserverStub()
        observer.categoriesSnapshot = .init(
            categories: [
                .init(id: "food", name: "Food", icon: "🍔", color: "green", amount: 12, currency: "USD")
            ]
        )
        let repository = MainFlowRepositorySpy()
        let output = ExpenseCategoryPickerOutputSpy()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            output: output,
            selectedCategoryID: "food"
        )

        await sut.fetchData()
        await sut.handleTapAdd()

        XCTAssertEqual(output.lastSelectedCategory?.id, "food")
        XCTAssertEqual(router.closeCallsCount, 1)
    }

    func testFetchDataShowsFailureWhenRefreshFailsAndNoCachedCategories() async {
        let presenter = ExpenseCategoryPickerPresenterSpy()
        let router = ExpenseCategoryPickerRouterSpy()
        let observer = MainFlowObserverStub()
        let repository = MainFlowRepositorySpy()
        repository.refreshCategoriesError = NSError(domain: "test", code: 1)
        let output = ExpenseCategoryPickerOutputSpy()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            output: output,
            selectedCategoryID: nil
        )

        await sut.fetchData()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter updates")
        }

        if case .failed = last.loadingState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected failed loading state")
        }
    }

    func testHandleTapCreateCategoryOpensCreateFlow() async {
        let presenter = ExpenseCategoryPickerPresenterSpy()
        let router = ExpenseCategoryPickerRouterSpy()
        let observer = MainFlowObserverStub()
        observer.categoriesSnapshot = .init(
            categories: [
                .init(id: "food", name: "Food", icon: "🍔", color: "green", amount: 12, currency: "USD")
            ]
        )
        let repository = MainFlowRepositorySpy()
        let output = ExpenseCategoryPickerOutputSpy()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            output: output,
            selectedCategoryID: nil
        )

        await sut.fetchData()
        await sut.handleTapCreateCategory()

        XCTAssertEqual(router.openCategoryCreateCallsCount, 1)
    }

    func testObservedCategoryUpdatesRefreshVisibleListWithoutSelectingNewCategory() async {
        let presenter = ExpenseCategoryPickerPresenterSpy()
        let router = ExpenseCategoryPickerRouterSpy()
        let observer = MainFlowObserverStub()
        let repository = MainFlowRepositorySpy()
        let output = ExpenseCategoryPickerOutputSpy()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            output: output,
            selectedCategoryID: nil
        )

        await sut.fetchData()
        observer.publishCategories(
            .init(
                categories: [
                    .init(id: "travel", name: "Travel", icon: "✈️", color: "#A0E7E5", amount: .zero, currency: "USD")
                ]
            )
        )
        await waitForUpdates()

        XCTAssertEqual(presenter.presentedData.last?.categories.map(\.id), ["travel"])
        XCTAssertNil(presenter.presentedData.last?.selectedCategoryID)
    }
}

private extension ExpenseCategoryPickerInteractorTests {
    func makeSut(
        presenter: ExpenseCategoryPickerPresentationLogic,
        router: ExpenseCategoryPickerRoutingLogic,
        repository: MainFlowDomainRepositoryProtocol,
        observer: MainFlowDomainObserverProtocol,
        output: ExpenseCategoryPickerOutput,
        selectedCategoryID: String?
    ) -> ExpenseCategoryPickerInteractor {
        ExpenseCategoryPickerInteractor(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            output: output,
            selectedCategoryID: selectedCategoryID
        )
    }

    func waitForUpdates() async {
        await Task.yield()
        await Task.yield()
    }
}

@MainActor
private final class ExpenseCategoryPickerPresenterSpy: ExpenseCategoryPickerPresentationLogic {
    private(set) var presentedData: [ExpenseCategoryPickerFetchData] = []

    func presentFetchedData(_ data: ExpenseCategoryPickerFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class ExpenseCategoryPickerRouterSpy: ExpenseCategoryPickerRoutingLogic {
    private(set) var closeCallsCount = 0
    private(set) var openCategoryCreateCallsCount = 0

    func close() {
        closeCallsCount += 1
    }

    func openCategoryCreate() {
        openCategoryCreateCallsCount += 1
    }
}

private final class ExpenseCategoryPickerOutputSpy: ExpenseCategoryPickerOutput, @unchecked Sendable {
    private(set) var lastSelectedCategory: ExpenseCategorySelectionModel?

    func handleDidSelectCategory(_ category: ExpenseCategorySelectionModel) async {
        lastSelectedCategory = category
    }
}

private final class MainFlowRepositorySpy: MainFlowDomainRepositoryProtocol, @unchecked Sendable {
    var refreshCategoriesError: Error?

    func refreshMainFlow() async throws {}
    func refreshCategories() async throws {
        if let refreshCategoriesError {
            throw refreshCategoriesError
        }
    }
    func refreshRecentExpenses() async throws {}
    func refreshCategoryFirstPage(id: String, fromDate: Date?) async throws {}
    func refreshExpensesFirstPage() async throws {}
    func handleCurrencyDidChange(_ payload: ProfileCurrencyDidChangePayload) async {}
    func loadNextCategoryPage(id: String) async throws {}
    func loadNextExpensesPage() async throws {}
    func addExpense(_ request: ExpensesCreateRequestDTO) async throws {}
    func deleteExpense(id: String) async throws {}
    func addCategory(_ request: CategoryCreateRequestDTO) async throws -> MainCategoryCardModel {
        .init(
            id: "created",
            name: request.name,
            icon: request.icon,
            color: request.color,
            amount: .zero,
            currency: "USD"
        )
    }
    func updateCategory(id: String, request: CategoryCreateRequestDTO) async throws -> MainCategoryCardModel {
        .init(
            id: id,
            name: request.name,
            icon: request.icon,
            color: request.color,
            amount: .zero,
            currency: "USD"
        )
    }
    func deleteCategory(id: String) async throws {}
    func clearSession() async {}
}

private final class MainFlowObserverStub: MainFlowDomainObserverProtocol, @unchecked Sendable {
    var categoriesSnapshot: MainFlowCategoriesSnapshot = .init()
    private var categoriesContinuation: AsyncStream<MainFlowCategoriesSnapshot>.Continuation?

    func subscribeOverview() -> AsyncStream<MainFlowOverviewSnapshot> { AsyncStream { $0.finish() } }
    func subscribeCategories() -> AsyncStream<MainFlowCategoriesSnapshot> {
        AsyncStream { continuation in
            categoriesContinuation = continuation
        }
    }
    func subscribeCategory(id: String) -> AsyncStream<MainFlowCategorySnapshot> { AsyncStream { $0.finish() } }
    func subscribeExpensesList() -> AsyncStream<MainFlowExpensesListSnapshot> { AsyncStream { $0.finish() } }
    func currentOverviewSnapshot() -> MainFlowOverviewSnapshot { .init() }
    func currentCategoriesSnapshot() -> MainFlowCategoriesSnapshot { categoriesSnapshot }
    func currentCategorySnapshot(id: String) -> MainFlowCategorySnapshot { .init(categoryID: id) }
    func currentExpensesListSnapshot() -> MainFlowExpensesListSnapshot { .init() }
    func publishAll(from store: MainFlowDomainStoreProtocol) {}
    func finishAll() {
        categoriesContinuation?.finish()
    }

    func publishCategories(_ snapshot: MainFlowCategoriesSnapshot) {
        categoriesSnapshot = snapshot
        categoriesContinuation?.yield(snapshot)
    }
}
