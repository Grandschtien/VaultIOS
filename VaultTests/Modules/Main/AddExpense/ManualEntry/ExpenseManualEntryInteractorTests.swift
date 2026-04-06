import XCTest
@testable import Vault

@MainActor
final class ExpenseManualEntryInteractorTests: XCTestCase {
    func testFetchDataBuildsSingleDraftFromProfileCurrency() async {
        let presenter = ExpenseManualEntryPresenterSpy()
        let sut = makeSUT(
            presenter: presenter,
            userProfileStorageService: UserProfileStorageSpy(
                profile: .init(
                    userId: "1",
                    email: "test@example.com",
                    name: "Test",
                    currency: "KZT",
                    language: "en"
                )
            )
        )

        await sut.fetchData()

        let last = presenter.presentedData.last
        XCTAssertEqual(last?.loadingState, .idle)
        XCTAssertEqual(last?.currentDraft?.currencyCode, "KZT")
        XCTAssertEqual(last?.primaryAction, .confirm)
        XCTAssertFalse(last?.isPrimaryEnabled ?? true)
        XCTAssertFalse(last?.isSkipVisible ?? true)
    }
}

extension ExpenseManualEntryInteractorTests {
    func testHandleTapCategoryOpensPickerForCurrentDraft() async {
        let router = ExpenseManualEntryRouterSpy()
        let sut = makeSUT(router: router)

        await sut.handleTapCategory()

        XCTAssertEqual(router.openCategoryPickerCallsCount, 1)
        XCTAssertNil(router.lastSelectedCategoryID)
    }

    func testHandleTapPrimaryButtonSavesSingleDraftAndCloses() async {
        let presenter = ExpenseManualEntryPresenterSpy()
        let router = ExpenseManualEntryRouterSpy()
        let repository = MainFlowRepositorySpy()
        let sut = makeSUT(
            presenter: presenter,
            router: router,
            repository: repository,
            initialDrafts: [
                .init(
                    amountText: "45,00",
                    titleText: "  Lunch at Nando's  ",
                    descriptionText: "  Quick lunch  ",
                    selectedCategory: .init(
                        id: "food",
                        name: "Food",
                        icon: "🍔",
                        color: "green"
                    ),
                    currencyCode: "GBP"
                )
            ]
        )

        let before = Date()
        await sut.handleTapPrimaryButton()
        let after = Date()

        let request = await repository.lastAddExpenseRequest()
        XCTAssertEqual(request?.expenses.count, 1)
        XCTAssertEqual(request?.expenses.first?.title, "Lunch at Nando's")
        XCTAssertEqual(request?.expenses.first?.description, "Quick lunch")
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

    func testHandleTapPrimaryButtonFailureShowsGenericError() async {
        let presenter = ExpenseManualEntryPresenterSpy()
        let router = ExpenseManualEntryRouterSpy()
        let repository = MainFlowRepositorySpy()
        await repository.setAddExpenseError(ExpenseManualEntryTestError.any)
        let sut = makeSUT(
            presenter: presenter,
            router: router,
            repository: repository,
            initialDrafts: [validDraft()]
        )

        await sut.handleTapPrimaryButton()

        XCTAssertEqual(router.closeCallsCount, 0)
        XCTAssertEqual(router.presentedErrors, [L10n.mainOverviewError])
        XCTAssertEqual(
            presenter.presentedData.last?.loadingState,
            .failed(.undelinedError(description: L10n.mainOverviewError))
        )
    }
}

extension ExpenseManualEntryInteractorTests {
    func testHandleTapPrimaryButtonAdvancesMultiDraftFlow() async {
        let presenter = ExpenseManualEntryPresenterSpy()
        let repository = MainFlowRepositorySpy()
        let sut = makeSUT(
            presenter: presenter,
            repository: repository,
            initialDrafts: [
                validDraft(title: "Coffee"),
                .init(currencyCode: "USD")
            ]
        )

        await sut.handleTapPrimaryButton()

        XCTAssertEqual(presenter.presentedData.last?.currentDraft?.currencyCode, "USD")
        XCTAssertEqual(presenter.presentedData.last?.primaryAction, .confirm)
        XCTAssertFalse(presenter.presentedData.last?.isSkipVisible ?? true)
        let request = await repository.lastAddExpenseRequest()
        XCTAssertNil(request)
    }

    func testHandleTapSkipAdvancesWithoutSaving() async {
        let presenter = ExpenseManualEntryPresenterSpy()
        let repository = MainFlowRepositorySpy()
        let sut = makeSUT(
            presenter: presenter,
            repository: repository,
            initialDrafts: [
                validDraft(title: "Coffee"),
                validDraft(title: "Taxi")
            ]
        )

        await sut.handleTapSkip()

        XCTAssertEqual(presenter.presentedData.last?.currentDraft?.titleText, "Taxi")
        let addExpenseCallsCount = await repository.addExpenseCallsCount()
        XCTAssertEqual(addExpenseCallsCount, 0)
    }

    func testFinalConfirmJumpsBackToFirstInvalidIncludedDraft() async {
        let presenter = ExpenseManualEntryPresenterSpy()
        let repository = MainFlowRepositorySpy()
        let sut = makeSUT(
            presenter: presenter,
            repository: repository,
            initialDrafts: [
                validDraft(title: "Coffee"),
                validDraft(title: "Taxi")
            ]
        )

        await sut.handleTapPrimaryButton()
        await sut.handleChangeCurrentPage(0)
        await sut.handleChangeTitle("   ")
        await sut.handleChangeCurrentPage(1)
        await sut.handleTapPrimaryButton()

        XCTAssertEqual(presenter.presentedData.last?.currentDraft?.titleText, "   ")
        let addExpenseCallsCount = await repository.addExpenseCallsCount()
        XCTAssertEqual(addExpenseCallsCount, 0)
    }

    func testHandleTapPrimaryButtonWhileLoadingIsIgnored() async {
        let repository = MainFlowRepositorySpy()
        await repository.setShouldSuspendAddExpense(true)
        let sut = makeSUT(
            repository: repository,
            initialDrafts: [validDraft()]
        )

        let startedExpectation = expectation(description: "request started")
        await repository.setOnAddExpense { _ in
            startedExpectation.fulfill()
        }

        let firstTapTask = Task {
            await sut.handleTapPrimaryButton()
        }

        await fulfillment(of: [startedExpectation], timeout: 1.0)
        await sut.handleTapPrimaryButton()

        let addExpenseCallsCount = await repository.addExpenseCallsCount()
        XCTAssertEqual(addExpenseCallsCount, 1)
        await repository.resumeAddExpense()
        _ = await firstTapTask.value
    }
}

@MainActor
private extension ExpenseManualEntryInteractorTests {
    func makeSUT(
        presenter: ExpenseManualEntryPresenterSpy? = nil,
        router: ExpenseManualEntryRouterSpy? = nil,
        repository: MainFlowRepositorySpy = .init(),
        observer: MainFlowObserverStub = .init(),
        userProfileStorageService: UserProfileStorageSpy = .init(),
        initialDrafts: [ExpenseEditableDraft] = []
    ) -> ExpenseManualEntryInteractor {
        let resolvedPresenter = presenter ?? ExpenseManualEntryPresenterSpy()
        let resolvedRouter = router ?? ExpenseManualEntryRouterSpy()
        return ExpenseManualEntryInteractor(
            presenter: resolvedPresenter,
            router: resolvedRouter,
            repository: repository,
            currencyCodeResolver: AddExpenseCurrencyCodeResolver(
                observer: observer,
                userProfileStorageService: userProfileStorageService
            ),
            requestBuilder: ExpenseManualEntryRequestBuilder(),
            initialDrafts: initialDrafts
        )
    }

    func validDraft(
        title: String = "Lunch"
    ) -> ExpenseEditableDraft {
        ExpenseEditableDraft(
            amountText: "45.00",
            titleText: title,
            descriptionText: "Morning",
            selectedCategory: .init(
                id: "food",
                name: "Food",
                icon: "🍔",
                color: "green"
            ),
            currencyCode: "USD"
        )
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
        AsyncStream { $0.finish() }
    }

    func subscribeCategories() -> AsyncStream<MainFlowCategoriesSnapshot> {
        AsyncStream { $0.finish() }
    }

    func subscribeCategory(id: String) -> AsyncStream<MainFlowCategorySnapshot> {
        AsyncStream { $0.finish() }
    }

    func subscribeExpensesList() -> AsyncStream<MainFlowExpensesListSnapshot> {
        AsyncStream { $0.finish() }
    }

    func currentOverviewSnapshot() -> MainFlowOverviewSnapshot {
        overviewSnapshot
    }

    func currentCategoriesSnapshot() -> MainFlowCategoriesSnapshot {
        categoriesSnapshot
    }

    func currentCategorySnapshot(id: String) -> MainFlowCategorySnapshot {
        .init(categoryID: id)
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
    func refreshCategoryFirstPage(id: String, fromDate: Date?) async throws {}
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
