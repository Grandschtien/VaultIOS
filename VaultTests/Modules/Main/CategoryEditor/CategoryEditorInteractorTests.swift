import XCTest
@testable import Vault

@MainActor
final class CategoryEditorInteractorTests: XCTestCase {
    func testFetchDataInCreateModeBuildsDefaultDraft() async {
        let presenter = CategoryEditorPresenterSpy()
        let sut = makeSUT(
            mode: .create,
            presenter: presenter
        )

        await sut.fetchData()

        let data = tryUnwrap(presenter.presentedData.last)
        XCTAssertEqual(data.mode, .create)
        XCTAssertEqual(data.loadingState, .loaded)
        XCTAssertEqual(data.draft.name, "")
        XCTAssertEqual(data.draft.emoji, presetProvider.defaultEmoji)
        XCTAssertEqual(data.draft.colorHex, presetProvider.defaultColorHex)
        XCTAssertFalse(data.isPrimaryEnabled)
        XCTAssertFalse(data.isDeleteVisible)
    }

    func testFetchDataInEditModePrefillsExistingCategory() async {
        let presenter = CategoryEditorPresenterSpy()
        let observer = CategoryEditorObserverStub()
        observer.categoriesSnapshot = .init(
            categories: [
                .init(
                    id: "food",
                    name: "Food",
                    icon: "🍔",
                    color: "light_blue",
                    amount: 20,
                    currency: "USD"
                )
            ]
        )
        let sut = makeSUT(
            mode: .edit(id: "food"),
            presenter: presenter,
            observer: observer
        )

        await sut.fetchData()

        let data = tryUnwrap(presenter.presentedData.last)
        XCTAssertEqual(data.loadingState, .loaded)
        XCTAssertEqual(data.draft.name, "Food")
        XCTAssertEqual(data.draft.emoji, "🍔")
        XCTAssertEqual(data.draft.colorHex, "#DBEBFC")
        XCTAssertTrue(data.isDeleteVisible)
        XCTAssertFalse(data.isPrimaryEnabled)
    }

    func testFetchDataInEditModeFailsWhenCategoryIsMissing() async {
        let presenter = CategoryEditorPresenterSpy()
        let repository = CategoryEditorRepositorySpy()
        repository.refreshCategoriesError = StubError.any
        repository.refreshCategoryError = StubError.any
        let sut = makeSUT(
            mode: .edit(id: "missing"),
            presenter: presenter,
            repository: repository
        )

        await sut.fetchData()

        let data = tryUnwrap(presenter.presentedData.last)
        if case .failed = data.loadingState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected failed loading state")
        }
    }

    func testFetchDataInEditModeHidesDeleteForUnmappedCategory() async {
        let presenter = CategoryEditorPresenterSpy()
        let observer = CategoryEditorObserverStub()
        observer.categorySnapshots["other"] = .init(
            categoryID: "other",
            category: .init(
                id: "other",
                name: L10n.other,
                icon: "📦",
                color: "#A0E7E5",
                amount: .zero,
                currency: "USD"
            )
        )
        let sut = makeSUT(
            mode: .edit(id: "other"),
            presenter: presenter,
            observer: observer
        )

        await sut.fetchData()

        XCTAssertEqual(presenter.presentedData.last?.isDeleteVisible, false)
    }
}

extension CategoryEditorInteractorTests {
    func testHandleTapPrimaryButtonWithInvalidDraftShowsNameError() async {
        let presenter = CategoryEditorPresenterSpy()
        let router = CategoryEditorRouterSpy()
        let sut = makeSUT(
            mode: .create,
            presenter: presenter,
            router: router
        )

        await sut.fetchData()
        await sut.handleTapPrimaryButton()

        let data = tryUnwrap(presenter.presentedData.last)
        XCTAssertTrue(data.shouldShowNameError)
        XCTAssertEqual(router.closeCallsCount, 0)
    }

    func testHandleTapPrimaryButtonInCreateModeAddsCategoryAndCloses() async {
        let presenter = CategoryEditorPresenterSpy()
        let router = CategoryEditorRouterSpy()
        let repository = CategoryEditorRepositorySpy()
        let sut = makeSUT(
            mode: .create,
            presenter: presenter,
            router: router,
            repository: repository
        )

        await sut.fetchData()
        await sut.handleChangeCategoryName("  Food  ")
        await sut.handleTapPrimaryButton()

        let request = repository.addCategoryRequest
        XCTAssertEqual(request?.name, "Food")
        XCTAssertEqual(request?.icon, presetProvider.defaultEmoji)
        XCTAssertEqual(request?.color, presetProvider.defaultColorHex)
        XCTAssertEqual(router.closeCallsCount, 1)
        XCTAssertEqual(router.presentedErrors, [])
    }

    func testHandleTapPrimaryButtonInEditModeUpdatesCategoryAndCloses() async {
        let presenter = CategoryEditorPresenterSpy()
        let router = CategoryEditorRouterSpy()
        let repository = CategoryEditorRepositorySpy()
        let observer = CategoryEditorObserverStub()
        observer.categorySnapshots["food"] = .init(
            categoryID: "food",
            category: .init(
                id: "food",
                name: "Food",
                icon: "🍔",
                color: "light_orange",
                amount: 12,
                currency: "USD"
            )
        )
        let sut = makeSUT(
            mode: .edit(id: "food"),
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer
        )

        await sut.fetchData()
        await sut.handleChangeCategoryName("Groceries")
        await sut.handleTapPrimaryButton()

        let request = repository.updateCategoryRequest
        XCTAssertEqual(request?.id, "food")
        XCTAssertEqual(request?.request.name, "Groceries")
        XCTAssertEqual(request?.request.icon, "🍔")
        XCTAssertEqual(request?.request.color, "#FFEDD6")
        XCTAssertEqual(router.closeCallsCount, 1)
    }

    func testHandleTapDeleteButtonDeletesCategoryAndCloses() async {
        let presenter = CategoryEditorPresenterSpy()
        let router = CategoryEditorRouterSpy()
        let repository = CategoryEditorRepositorySpy()
        let observer = CategoryEditorObserverStub()
        observer.categorySnapshots["food"] = .init(
            categoryID: "food",
            category: .init(
                id: "food",
                name: "Food",
                icon: "🍔",
                color: "#A0E7E5",
                amount: 12,
                currency: "USD"
            )
        )
        let sut = makeSUT(
            mode: .edit(id: "food"),
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer
        )

        await sut.fetchData()
        await sut.handleTapDeleteButton()

        let deletedCategoryID = repository.deletedCategoryID
        XCTAssertEqual(deletedCategoryID, "food")
        XCTAssertEqual(router.closeCallsCount, 1)
    }
}

extension CategoryEditorInteractorTests {
    func testHandleTapCustomEmojiButtonOpensPickerAndSelectedEmojiUpdatesDraft() async {
        let presenter = CategoryEditorPresenterSpy()
        let router = CategoryEditorRouterSpy()
        let sut = makeSUT(
            mode: .create,
            presenter: presenter,
            router: router
        )

        await sut.fetchData()
        await sut.handleTapCustomEmojiButton()
        await sut.handleDidSelectEmoji("🎁")

        XCTAssertEqual(router.openEmojiPickerCalls.last, presetProvider.defaultEmoji)
        XCTAssertEqual(presenter.presentedData.last?.draft.emoji, "🎁")
    }

    func testHandleTapCustomColorButtonOpensPickerAndSelectedColorUpdatesDraft() async {
        let presenter = CategoryEditorPresenterSpy()
        let router = CategoryEditorRouterSpy()
        let sut = makeSUT(
            mode: .create,
            presenter: presenter,
            router: router
        )

        await sut.fetchData()
        await sut.handleTapCustomColorButton()
        await sut.handleDidSelectCustomColor("#123456")

        XCTAssertEqual(router.openColorPickerCalls.last, presetProvider.defaultColorHex)
        XCTAssertEqual(presenter.presentedData.last?.draft.colorHex, "#123456")
    }

    func testHandleChangeCategoryNameEnablesSaveWhenEditDraftChanges() async {
        let presenter = CategoryEditorPresenterSpy()
        let observer = CategoryEditorObserverStub()
        observer.categorySnapshots["food"] = .init(
            categoryID: "food",
            category: .init(
                id: "food",
                name: "Food",
                icon: "🍔",
                color: "#A0E7E5",
                amount: 12,
                currency: "USD"
            )
        )
        let sut = makeSUT(
            mode: .edit(id: "food"),
            presenter: presenter,
            observer: observer
        )

        await sut.fetchData()
        await sut.handleChangeCategoryName("Food & Dining")

        XCTAssertEqual(presenter.presentedData.last?.draft.name, "Food & Dining")
        XCTAssertEqual(presenter.presentedData.last?.isPrimaryEnabled, true)
    }
}

private extension CategoryEditorInteractorTests {
    var presetProvider: CategoryEditorPresetProvider {
        CategoryEditorPresetProvider()
    }

    enum StubError: Error {
        case any
    }

    func makeSUT(
        mode: CategoryEditorMode,
        presenter: CategoryEditorPresenterSpy,
        router: CategoryEditorRouterSpy? = nil,
        repository: CategoryEditorRepositorySpy = .init(),
        observer: CategoryEditorObserverStub = .init()
    ) -> CategoryEditorInteractor {
        let resolvedRouter = router ?? CategoryEditorRouterSpy()

        return CategoryEditorInteractor(
            mode: mode,
            presenter: presenter,
            router: resolvedRouter,
            repository: repository,
            observer: observer,
            presetProvider: presetProvider,
            colorProvider: CategoryColorProvider()
        )
    }

    func tryUnwrap<T>(
        _ value: T?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> T {
        guard let value else {
            XCTFail("Expected value", file: file, line: line)
            fatalError("Missing expected value")
        }

        return value
    }
}

@MainActor
private final class CategoryEditorPresenterSpy: CategoryEditorPresentationLogic {
    private(set) var presentedData: [CategoryEditorFetchData] = []

    func presentFetchedData(_ data: CategoryEditorFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class CategoryEditorRouterSpy: CategoryEditorRoutingLogic {
    private(set) var closeCallsCount = 0
    private(set) var openEmojiPickerCalls: [String] = []
    private(set) var openColorPickerCalls: [String] = []
    private(set) var presentedErrors: [String] = []

    func close() {
        closeCallsCount += 1
    }

    func openEmojiPicker(selectedEmoji: String, output: CategoryEmojiPickerOutput) {
        openEmojiPickerCalls.append(selectedEmoji)
    }

    func openColorPicker(selectedHex: String) {
        openColorPickerCalls.append(selectedHex)
    }

    func presentError(with text: String) {
        presentedErrors.append(text)
    }
}

private final class CategoryEditorRepositorySpy: MainFlowDomainRepositoryProtocol, @unchecked Sendable {
    var refreshCategoriesError: Error?
    var refreshCategoryError: Error?
    var addCategoryRequest: CategoryCreateRequestDTO?
    var updateCategoryRequest: (id: String, request: CategoryCreateRequestDTO)?
    var deletedCategoryID: String?

    func refreshMainFlow() async throws {}

    func refreshCategories() async throws {
        if let refreshCategoriesError {
            throw refreshCategoriesError
        }
    }

    func refreshRecentExpenses() async throws {}

    func refreshCategoryFirstPage(id: String, fromDate: Date?) async throws {
        if let refreshCategoryError {
            throw refreshCategoryError
        }
    }

    func refreshExpensesFirstPage() async throws {}
    func handleCurrencyDidChange(_ payload: ProfileCurrencyDidChangePayload) async {}
    func loadNextCategoryPage(id: String) async throws {}
    func loadNextExpensesPage() async throws {}
    func addExpense(_ request: ExpensesCreateRequestDTO) async throws {}
    func deleteExpense(id: String) async throws {}

    func addCategory(_ request: CategoryCreateRequestDTO) async throws -> MainCategoryCardModel {
        addCategoryRequest = request
        return .init(
            id: "created",
            name: request.name,
            icon: request.icon,
            color: request.color,
            amount: .zero,
            currency: "USD"
        )
    }

    func updateCategory(id: String, request: CategoryCreateRequestDTO) async throws -> MainCategoryCardModel {
        updateCategoryRequest = (id, request)
        return .init(
            id: id,
            name: request.name,
            icon: request.icon,
            color: request.color,
            amount: .zero,
            currency: "USD"
        )
    }

    func deleteCategory(id: String) async throws {
        deletedCategoryID = id
    }

    func clearSession() async {}
}

private final class CategoryEditorObserverStub: MainFlowDomainObserverProtocol, @unchecked Sendable {
    var categoriesSnapshot: MainFlowCategoriesSnapshot = .init()
    var categorySnapshots: [String: MainFlowCategorySnapshot] = [:]

    func subscribeOverview() -> AsyncStream<MainFlowOverviewSnapshot> { AsyncStream { $0.finish() } }
    func subscribeCategories() -> AsyncStream<MainFlowCategoriesSnapshot> { AsyncStream { $0.finish() } }
    func subscribeCategory(id: String) -> AsyncStream<MainFlowCategorySnapshot> { AsyncStream { $0.finish() } }
    func subscribeExpensesList() -> AsyncStream<MainFlowExpensesListSnapshot> { AsyncStream { $0.finish() } }
    func currentOverviewSnapshot() -> MainFlowOverviewSnapshot { .init() }
    func currentCategoriesSnapshot() -> MainFlowCategoriesSnapshot { categoriesSnapshot }
    func currentCategorySnapshot(id: String) -> MainFlowCategorySnapshot { categorySnapshots[id] ?? .init(categoryID: id) }
    func currentExpensesListSnapshot() -> MainFlowExpensesListSnapshot { .init() }
    func publishAll(from store: MainFlowDomainStoreProtocol) {}
    func finishAll() {}
}
