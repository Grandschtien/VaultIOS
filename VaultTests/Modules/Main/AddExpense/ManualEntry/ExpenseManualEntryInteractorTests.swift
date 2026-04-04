import XCTest
@testable import Vault

@MainActor
final class ExpenseManualEntryInteractorTests: XCTestCase {
    func testFetchDataBuildsEmptyDraft() async {
        let presenter = ExpenseManualEntryPresenterSpy()
        let router = ExpenseManualEntryRouterSpy()
        let repository = MainFlowRepositorySpy()
        let observer = MainFlowObserverStub()
        let userProfileStorageService = UserProfileStorageSpy(
            profile: .init(
                userId: "1",
                email: "test@example.com",
                name: "Test",
                currency: "KZT",
                language: "en"
            )
        )
        let sut = ExpenseManualEntryInteractor(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            userProfileStorageService: userProfileStorageService,
            requestBuilder: ExpenseManualEntryRequestBuilder()
        )

        await sut.fetchData()

        let last = presenter.presentedData.last
        XCTAssertEqual(last?.loadingState, .idle)
        XCTAssertFalse(last?.isConfirmEnabled ?? true)
        XCTAssertEqual(last?.amountText, "")
        XCTAssertEqual(last?.titleText, "")
        XCTAssertEqual(last?.descriptionText, "")
        XCTAssertEqual(last?.currencyCode, "KZT")
        XCTAssertNil(last?.selectedCategory)
    }

    func testHandleFieldChangesUpdateDraft() async {
        let presenter = ExpenseManualEntryPresenterSpy()
        let router = ExpenseManualEntryRouterSpy()
        let repository = MainFlowRepositorySpy()
        let observer = MainFlowObserverStub()
        let userProfileStorageService = UserProfileStorageSpy()
        let sut = ExpenseManualEntryInteractor(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            userProfileStorageService: userProfileStorageService,
            requestBuilder: ExpenseManualEntryRequestBuilder()
        )

        await sut.handleChangeAmount("45.00")
        await sut.handleChangeTitle("Lunch at Nando's")
        await sut.handleChangeDescription("Quick lunch after the project milestone.")

        let last = presenter.presentedData.last
        XCTAssertEqual(last?.amountText, "45.00")
        XCTAssertEqual(last?.titleText, "Lunch at Nando's")
        XCTAssertEqual(last?.descriptionText, "Quick lunch after the project milestone.")
    }

    func testHandleTapCategoryOpensPicker() async {
        let presenter = ExpenseManualEntryPresenterSpy()
        let router = ExpenseManualEntryRouterSpy()
        let repository = MainFlowRepositorySpy()
        let observer = MainFlowObserverStub()
        let userProfileStorageService = UserProfileStorageSpy()
        let sut = ExpenseManualEntryInteractor(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            userProfileStorageService: userProfileStorageService,
            requestBuilder: ExpenseManualEntryRequestBuilder()
        )

        await sut.handleTapCategory()

        XCTAssertEqual(router.openCategoryPickerCallsCount, 1)
        XCTAssertNil(router.lastSelectedCategoryID)
    }

    func testHandleDidSelectCategoryUpdatesDraft() async {
        let presenter = ExpenseManualEntryPresenterSpy()
        let router = ExpenseManualEntryRouterSpy()
        let repository = MainFlowRepositorySpy()
        let observer = MainFlowObserverStub()
        let userProfileStorageService = UserProfileStorageSpy()
        let sut = ExpenseManualEntryInteractor(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            userProfileStorageService: userProfileStorageService,
            requestBuilder: ExpenseManualEntryRequestBuilder()
        )

        await sut.handleDidSelectCategory(
            .init(
                id: "food",
                name: "Food & Dining",
                icon: "🍔",
                color: "green"
            )
        )

        XCTAssertEqual(presenter.presentedData.last?.selectedCategory?.id, "food")
        XCTAssertEqual(presenter.presentedData.last?.selectedCategory?.name, "Food & Dining")
    }

    func testValidDraftEnablesConfirm() async {
        let presenter = ExpenseManualEntryPresenterSpy()
        let router = ExpenseManualEntryRouterSpy()
        let repository = MainFlowRepositorySpy()
        let observer = MainFlowObserverStub()
        let userProfileStorageService = UserProfileStorageSpy()
        let sut = ExpenseManualEntryInteractor(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            userProfileStorageService: userProfileStorageService,
            requestBuilder: ExpenseManualEntryRequestBuilder()
        )

        await sut.handleChangeAmount("45.00")
        await sut.handleChangeTitle("Lunch at Nando's")
        await sut.handleDidSelectCategory(
            .init(
                id: "food",
                name: "Food & Dining",
                icon: "🍔",
                color: "green"
            )
        )

        XCTAssertTrue(presenter.presentedData.last?.isConfirmEnabled ?? false)
    }

    func testHandleTapConfirmSuccessClosesFlow() async {
        let presenter = ExpenseManualEntryPresenterSpy()
        let router = ExpenseManualEntryRouterSpy()
        let repository = MainFlowRepositorySpy()
        let observer = MainFlowObserverStub(
            overviewSnapshot: MainFlowOverviewSnapshot(
                summary: MainSummaryModel(
                    totalAmount: 0,
                    currency: "EUR",
                    changePercent: 0
                )
            )
        )
        let userProfileStorageService = UserProfileStorageSpy(
            profile: .init(
                userId: "1",
                email: "test@example.com",
                name: "Test",
                currency: "GBP",
                language: "en"
            )
        )
        let sut = ExpenseManualEntryInteractor(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            userProfileStorageService: userProfileStorageService,
            requestBuilder: ExpenseManualEntryRequestBuilder()
        )

        await sut.handleChangeAmount("45,00")
        await sut.handleChangeTitle("  Lunch at Nando's  ")
        await sut.handleChangeDescription("  Quick lunch after the project milestone.  ")
        await sut.handleDidSelectCategory(
            .init(
                id: "food",
                name: "Food & Dining",
                icon: "🍔",
                color: "green"
            )
        )

        let before = Date()
        await sut.handleTapConfirm()
        let after = Date()

        let request = await repository.lastAddExpenseRequest()
        XCTAssertEqual(request?.expenses.count, 1)
        XCTAssertEqual(request?.expenses.first?.title, "Lunch at Nando's")
        XCTAssertEqual(request?.expenses.first?.description, "Quick lunch after the project milestone.")
        XCTAssertEqual(request?.expenses.first?.amount, 45)
        XCTAssertEqual(request?.expenses.first?.currency, "GBP")
        XCTAssertEqual(request?.expenses.first?.category, "food")
        XCTAssertEqual(router.closeCallsCount, 1)
        XCTAssertTrue(router.presentedErrors.isEmpty)
        XCTAssertEqual(presenter.presentedData.last?.loadingState, .loading)

        if let timeOfAdd = request?.expenses.first?.timeOfAdd {
            XCTAssertGreaterThanOrEqual(timeOfAdd, before)
            XCTAssertLessThanOrEqual(timeOfAdd, after)
        } else {
            XCTFail("Expected timeOfAdd")
        }
    }

    func testHandleTapConfirmFailureShowsGenericError() async {
        let presenter = ExpenseManualEntryPresenterSpy()
        let router = ExpenseManualEntryRouterSpy()
        let repository = MainFlowRepositorySpy()
        let observer = MainFlowObserverStub()
        let userProfileStorageService = UserProfileStorageSpy()
        let sut = ExpenseManualEntryInteractor(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            userProfileStorageService: userProfileStorageService,
            requestBuilder: ExpenseManualEntryRequestBuilder()
        )

        await repository.setAddExpenseError(ExpenseManualEntryTestError.any)
        await sut.handleChangeAmount("45.00")
        await sut.handleChangeTitle("Lunch at Nando's")
        await sut.handleDidSelectCategory(
            .init(
                id: "food",
                name: "Food & Dining",
                icon: "🍔",
                color: "green"
            )
        )

        await sut.handleTapConfirm()

        XCTAssertEqual(router.closeCallsCount, 0)
        XCTAssertEqual(router.presentedErrors, [L10n.mainOverviewError])
        XCTAssertEqual(
            presenter.presentedData.last?.loadingState,
            .failed(.undelinedError(description: L10n.mainOverviewError))
        )
        XCTAssertTrue(presenter.presentedData.last?.isConfirmEnabled ?? false)
    }

    func testHandleTapConfirmWhileLoadingIsIgnored() async {
        let presenter = ExpenseManualEntryPresenterSpy()
        let router = ExpenseManualEntryRouterSpy()
        let repository = MainFlowRepositorySpy()
        let observer = MainFlowObserverStub()
        let userProfileStorageService = UserProfileStorageSpy()
        let sut = ExpenseManualEntryInteractor(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            userProfileStorageService: userProfileStorageService,
            requestBuilder: ExpenseManualEntryRequestBuilder()
        )

        let addExpenseStartedExpectation = expectation(description: "First request started")
        await repository.setShouldSuspendAddExpense(true)
        await repository.setOnAddExpense { _ in
            addExpenseStartedExpectation.fulfill()
        }

        await sut.handleChangeAmount("45.00")
        await sut.handleChangeTitle("Lunch at Nando's")
        await sut.handleDidSelectCategory(
            .init(
                id: "food",
                name: "Food & Dining",
                icon: "🍔",
                color: "green"
            )
        )

        let firstTapTask = Task {
            await sut.handleTapConfirm()
        }

        await fulfillment(of: [addExpenseStartedExpectation], timeout: 1.0)
        await sut.handleTapConfirm()

        let addExpenseCallsCount = await repository.addExpenseCallsCount()
        XCTAssertEqual(addExpenseCallsCount, 1)

        await repository.resumeAddExpense()
        await firstTapTask.value
    }
}

@MainActor
private final class ExpenseManualEntryPresenterSpy: ExpenseManualEntryPresentationLogic {
    private(set) var presentedData: [ExpenseManualEntryFetchData] = []

    func presentFetchedData(_ data: ExpenseManualEntryFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class ExpenseManualEntryRouterSpy: ExpenseManualEntryRoutingLogic {
    private(set) var openCategoryPickerCallsCount = 0
    private(set) var closeCallsCount = 0
    private(set) var presentedErrors: [String] = []
    private(set) var lastSelectedCategoryID: String?

    func openCategoryPicker(
        selectedCategoryID: String?,
        output: ExpenseCategoryPickerOutput
    ) {
        openCategoryPickerCallsCount += 1
        lastSelectedCategoryID = selectedCategoryID
    }

    func close() {
        closeCallsCount += 1
    }

    func presentError(with text: String) {
        presentedErrors.append(text)
    }
}

private final class MainFlowObserverStub: MainFlowDomainObserverProtocol, @unchecked Sendable {
    private let overviewSnapshot: MainFlowOverviewSnapshot
    private let categoriesSnapshot: MainFlowCategoriesSnapshot

    init(
        overviewSnapshot: MainFlowOverviewSnapshot = .init(),
        categoriesSnapshot: MainFlowCategoriesSnapshot = .init()
    ) {
        self.overviewSnapshot = overviewSnapshot
        self.categoriesSnapshot = categoriesSnapshot
    }

    func subscribeOverview() -> AsyncStream<MainFlowOverviewSnapshot> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func subscribeCategories() -> AsyncStream<MainFlowCategoriesSnapshot> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func subscribeCategory(id: String) -> AsyncStream<MainFlowCategorySnapshot> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func subscribeExpensesList() -> AsyncStream<MainFlowExpensesListSnapshot> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func currentOverviewSnapshot() -> MainFlowOverviewSnapshot {
        overviewSnapshot
    }

    func currentCategoriesSnapshot() -> MainFlowCategoriesSnapshot {
        categoriesSnapshot
    }

    func currentCategorySnapshot(id: String) -> MainFlowCategorySnapshot {
        MainFlowCategorySnapshot(categoryID: id)
    }

    func currentExpensesListSnapshot() -> MainFlowExpensesListSnapshot {
        .init()
    }

    func publishAll(from store: MainFlowDomainStoreProtocol) {}

    func finishAll() {}
}

private enum ExpenseManualEntryTestError: Error {
    case any
}

private final class UserProfileStorageSpy: UserProfileStorageServiceProtocol, @unchecked Sendable {
    private var profile: UserProfileDefaults?

    init(profile: UserProfileDefaults? = nil) {
        self.profile = profile
    }

    func saveProfile(_ profile: UserProfileDefaults) {
        self.profile = profile
    }

    func loadProfile() -> UserProfileDefaults? {
        profile
    }

    func clearProfile() {
        profile = nil
    }
}

private actor MainFlowRepositorySpy: MainFlowDomainRepositoryProtocol {
    private var capturedAddExpenseRequest: ExpensesCreateRequestDTO?
    private var addExpenseCallCount = 0
    private var addExpenseError: Error?
    private var shouldSuspendAddExpense = false
    private var addExpenseContinuation: CheckedContinuation<Void, Never>?
    private var onAddExpense: (@Sendable (ExpensesCreateRequestDTO) -> Void)?

    func setAddExpenseError(_ error: Error?) {
        addExpenseError = error
    }

    func setShouldSuspendAddExpense(_ shouldSuspend: Bool) {
        shouldSuspendAddExpense = shouldSuspend
    }

    func setOnAddExpense(_ closure: @escaping @Sendable (ExpensesCreateRequestDTO) -> Void) {
        onAddExpense = closure
    }

    func lastAddExpenseRequest() -> ExpensesCreateRequestDTO? {
        capturedAddExpenseRequest
    }

    func addExpenseCallsCount() -> Int {
        addExpenseCallCount
    }

    func resumeAddExpense() {
        addExpenseContinuation?.resume()
        addExpenseContinuation = nil
        shouldSuspendAddExpense = false
    }

    func refreshMainFlow() async throws {}
    func refreshCategories() async throws {}
    func refreshRecentExpenses() async throws {}
    func refreshCategoryFirstPage(id: String) async throws {}
    func refreshExpensesFirstPage() async throws {}
    func handleCurrencyDidChange(_ payload: ProfileCurrencyDidChangePayload) async {}
    func loadNextCategoryPage(id: String) async throws {}
    func loadNextExpensesPage() async throws {}

    func addExpense(_ request: ExpensesCreateRequestDTO) async throws {
        addExpenseCallCount += 1
        capturedAddExpenseRequest = request
        onAddExpense?(request)

        if shouldSuspendAddExpense {
            await withCheckedContinuation { continuation in
                addExpenseContinuation = continuation
            }
        }

        if let addExpenseError {
            throw addExpenseError
        }
    }

    func deleteExpense(id: String) async throws {}
    func addCategory(_ request: CategoryCreateRequestDTO) async throws {}
    func deleteCategory(id: String) async throws {}
    func clearSession() async {}
}
