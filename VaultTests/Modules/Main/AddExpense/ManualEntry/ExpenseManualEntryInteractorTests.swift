import XCTest
@testable import Vylok

@MainActor
final class ExpenseManualEntryInteractorTests: XCTestCase {
    private var presenter: ExpenseManualEntryPresentationLogicMock!
    private var router: ExpenseManualEntryRoutingLogicMock!
    private var repository: MainFlowDomainRepositoryProtocolMock!
    private var observer: MainFlowDomainObserverProtocolMock!
    private var userProfileStorageService: UserProfileStorageServiceProtocolMock!

    override func setUp() {
        super.setUp()
        presenter = ExpenseManualEntryPresentationLogicMock()
        router = ExpenseManualEntryRoutingLogicMock()
        repository = MainFlowDomainRepositoryProtocolMock()
        observer = MainFlowDomainObserverProtocolMock()
        observer.currentOverviewSnapshotReturnValue = .init()
        observer.currentCategoriesSnapshotReturnValue = .init()
        userProfileStorageService = UserProfileStorageServiceProtocolMock()
    }

    override func tearDown() {
        userProfileStorageService = nil
        observer = nil
        repository = nil
        router = nil
        presenter = nil
        super.tearDown()
    }
}

extension ExpenseManualEntryInteractorTests {
    func testFetchDataBuildsSingleDraftFromProfileCurrency() async {
        userProfileStorageService.loadProfileReturnValue = UserProfileDefaultsFixtures.makeProfile(currency: "KZT")
        let sut = makeSUT()

        await sut.fetchData()

        let last = presenter.presentFetchedDataReceivedInvocations.last
        XCTAssertEqual(last?.loadingState, .idle)
        XCTAssertEqual(last?.currentDraft?.currencyCode, "KZT")
        XCTAssertEqual(last?.primaryAction, .confirm)
        XCTAssertFalse(last?.isPrimaryEnabled ?? true)
        XCTAssertFalse(last?.isSkipVisible ?? true)
    }
}

extension ExpenseManualEntryInteractorTests {
    func testHandleTapCategoryOpensPickerForCurrentDraft() async {
        let sut = makeSUT()

        await sut.handleTapCategory()

        XCTAssertEqual(router.openCategoryPickerSelectedCategoryIDOutputCallsCount, 1)
        XCTAssertNil(router.openCategoryPickerSelectedCategoryIDOutputReceivedInvocations.last?.selectedCategoryID)
    }

    func testHandleTapPrimaryButtonSavesSingleDraftAndCloses() async {
        let sut = makeSUT(
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

        let request = repository.addExpenseReceivedArguments
        XCTAssertEqual(request?.expenses.count, 1)
        XCTAssertEqual(request?.expenses.first?.title, "Lunch at Nando's")
        XCTAssertEqual(request?.expenses.first?.description, "Quick lunch")
        XCTAssertEqual(request?.expenses.first?.amount, 45)
        XCTAssertEqual(request?.expenses.first?.currency, "GBP")
        XCTAssertEqual(request?.expenses.first?.category, "food")
        XCTAssertEqual(router.closeCallsCount, 1)
        XCTAssertTrue(router.presentErrorWithReceivedInvocations.isEmpty)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.loadingState, .loading)

        if let timeOfAdd = request?.expenses.first?.timeOfAdd {
            XCTAssertGreaterThanOrEqual(timeOfAdd, before)
            XCTAssertLessThanOrEqual(timeOfAdd, after)
        } else {
            XCTFail("Expected timeOfAdd")
        }
    }

    func testHandleTapPrimaryButtonFailureShowsGenericError() async {
        repository.addExpenseThrowableError = TestError.any
        let sut = makeSUT(
            initialDrafts: [validDraft()]
        )

        await sut.handleTapPrimaryButton()

        XCTAssertEqual(router.closeCallsCount, 0)
        XCTAssertEqual(router.presentErrorWithReceivedInvocations, [L10n.mainOverviewError])
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations.last?.loadingState,
            .failed(.undelinedError(description: L10n.mainOverviewError))
        )
    }
}

extension ExpenseManualEntryInteractorTests {
    func testHandleTapPrimaryButtonAdvancesMultiDraftFlow() async {
        let sut = makeSUT(
            initialDrafts: [
                validDraft(title: "Coffee"),
                .init(currencyCode: "USD")
            ]
        )

        await sut.handleTapPrimaryButton()

        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.currentDraft?.currencyCode, "USD")
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.primaryAction, .confirm)
        XCTAssertFalse(presenter.presentFetchedDataReceivedInvocations.last?.isSkipVisible ?? true)
        let request = repository.addExpenseReceivedArguments
        XCTAssertNil(request)
    }

    func testHandleTapSkipAdvancesWithoutSaving() async {
        let sut = makeSUT(
            initialDrafts: [
                validDraft(title: "Coffee"),
                validDraft(title: "Taxi")
            ]
        )

        await sut.handleTapSkip()

        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.currentDraft?.titleText, "Taxi")
        let addExpenseCallsCount = repository.addExpenseCallsCount
        XCTAssertEqual(addExpenseCallsCount, 0)
    }

    func testFinalConfirmJumpsBackToFirstInvalidIncludedDraft() async {
        let sut = makeSUT(
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

        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.currentDraft?.titleText, "   ")
        let addExpenseCallsCount = repository.addExpenseCallsCount
        XCTAssertEqual(addExpenseCallsCount, 0)
    }

    func testHandleTapPrimaryButtonWhileLoadingIsIgnored() async {
        let sut = makeSUT(initialDrafts: [validDraft()])
        let startedExpectation = expectation(description: "request started")
        let (resumeStream, resumeContinuation) = AsyncStream.makeStream(of: Void.self)
        repository.addExpenseClosure = { _ in
            startedExpectation.fulfill()
            for await _ in resumeStream {
                break
            }
        }
        let firstTapTask = Task {
            await sut.handleTapPrimaryButton()
        }
        await fulfillment(of: [startedExpectation], timeout: 1.0)

        await sut.handleTapPrimaryButton()

        XCTAssertEqual(repository.addExpenseCallsCount, 1)
        resumeContinuation.yield(())
        _ = await firstTapTask.value
    }
}

private extension ExpenseManualEntryInteractorTests {
    func makeSUT(initialDrafts: [ExpenseEditableDraft] = []) -> ExpenseManualEntryInteractor {
        ExpenseManualEntryInteractor(
            presenter: presenter,
            router: router,
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
