import XCTest
@testable import Vylok

final class ExpesiesListInteractorTests: XCTestCase {
    private var presenter: ExpesiesListPresentationLogicMock!
    private var router: ExpesiesListRoutingLogicMock!
    private var repository: MainFlowDomainRepositoryProtocolMock!
    private var observer: MainFlowDomainObserverProtocolMock!
    private var analytics: ExpesiesListAnalyticsTrackingMock!
    private var sut: ExpesiesListInteractor!

    override func setUp() {
        super.setUp()
        presenter = ExpesiesListPresentationLogicMock()
        router = ExpesiesListRoutingLogicMock()
        repository = MainFlowDomainRepositoryProtocolMock()
        observer = MainFlowDomainObserverProtocolMock()
        analytics = ExpesiesListAnalyticsTrackingMock()
        observer.subscribeExpensesListReturnValue = AsyncStream { $0.finish() }
        observer.currentExpensesListSnapshotReturnValue = MainFlowExpensesListSnapshot()
        sut = ExpesiesListInteractor(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            analytics: analytics
        )
    }

    override func tearDown() {
        sut = nil
        analytics = nil
        observer = nil
        repository = nil
        router = nil
        presenter = nil
        super.tearDown()
    }
}

// MARK: - fetchData

extension ExpesiesListInteractorTests {
    func testFetchDataWhenRefreshSucceedsPresentsObservedSnapshot() async {
        // Arrange
        observer.currentExpensesListSnapshotReturnValue = MainFlowExpensesListSnapshot(
            categories: [MainModelFixtures.makeCategory()],
            expenseGroups: [MainModelFixtures.makeExpenseGroup()],
            hasMore: true
        )

        // Act
        await sut.fetchData()

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                ExpesiesListFetchData(loadingState: .loading, hasMore: false),
                ExpesiesListFetchData(
                    loadingState: .loaded,
                    categories: [MainModelFixtures.makeCategory()],
                    expenseGroups: [MainModelFixtures.makeExpenseGroup()],
                    hasMore: true
                )
            ]
        )
        XCTAssertEqual(repository.refreshExpensesFirstPageCallsCount, 1)
        XCTAssertEqual(repository.refreshCategoriesCallsCount, 1)
        XCTAssertEqual(analytics.trackScreenOpenCallsCount, 1)
        XCTAssertEqual(analytics.trackScreenSuccessCallsCount, 1)
    }

    func testFetchDataWhenRefreshFailsWithoutCachedExpensesPresentsFailedState() async {
        // Arrange
        repository.refreshExpensesFirstPageThrowableError = TestError.any

        // Act
        await sut.fetchData()

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                ExpesiesListFetchData(loadingState: .loading, hasMore: false),
                ExpesiesListFetchData(
                    loadingState: .failed(.undelinedError(description: TestError.any.localizedDescription)),
                    hasMore: false
                )
            ]
        )
        XCTAssertEqual(analytics.trackScreenFailureCallsCount, 1)
    }

    func testFetchDataWhenRefreshFailsWithCachedExpensesPresentsLoadedState() async {
        // Arrange
        repository.refreshExpensesFirstPageThrowableError = TestError.any
        observer.currentExpensesListSnapshotReturnValue = MainFlowExpensesListSnapshot(
            expenseGroups: [MainModelFixtures.makeExpenseGroup()]
        )

        // Act
        await sut.fetchData()

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                ExpesiesListFetchData(loadingState: .loading, hasMore: false),
                ExpesiesListFetchData(
                    loadingState: .loaded,
                    expenseGroups: [MainModelFixtures.makeExpenseGroup()],
                    hasMore: false
                )
            ]
        )
        XCTAssertEqual(analytics.trackScreenSuccessCallsCount, 1)
    }
}

// MARK: - handleLoadNextPage

extension ExpesiesListInteractorTests {
    func testHandleLoadNextPageWhenMorePagesExistLoadsNextPage() async {
        // Arrange
        let firstPage = MainFlowExpensesListSnapshot(
            expenseGroups: [MainModelFixtures.makeExpenseGroup()],
            hasMore: true
        )
        let secondPage = MainFlowExpensesListSnapshot(
            expenseGroups: [
                MainModelFixtures.makeExpenseGroup(),
                MainModelFixtures.makeExpenseGroup(expenses: [MainModelFixtures.makeExpense(id: "expense-2")])
            ],
            hasMore: false
        )
        observer.currentExpensesListSnapshotReturnValue = firstPage
        await sut.fetchData()
        observer.currentExpensesListSnapshotReturnValue = secondPage

        // Act
        await sut.handleLoadNextPage()

        // Assert
        XCTAssertEqual(repository.loadNextExpensesPageCallsCount, 1)
        XCTAssertEqual(
            Array(presenter.presentFetchedDataReceivedInvocations.dropFirst(2)),
            [
                ExpesiesListFetchData(
                    loadingState: .loaded,
                    expenseGroups: firstPage.expenseGroups,
                    isLoadingNextPage: true,
                    hasMore: true
                ),
                ExpesiesListFetchData(
                    loadingState: .loaded,
                    expenseGroups: secondPage.expenseGroups,
                    hasMore: false
                )
            ]
        )
    }

    func testHandleLoadNextPageWhenLoadingFailsPresentsError() async {
        // Arrange
        observer.currentExpensesListSnapshotReturnValue = MainFlowExpensesListSnapshot(
            expenseGroups: [MainModelFixtures.makeExpenseGroup()],
            hasMore: true
        )
        await sut.fetchData()
        repository.loadNextExpensesPageThrowableError = TestError.any

        // Act
        await sut.handleLoadNextPage()

        // Assert
        XCTAssertEqual(router.presentErrorWithReceivedInvocations, [L10n.mainOverviewError])
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations.last,
            ExpesiesListFetchData(
                loadingState: .loaded,
                expenseGroups: [MainModelFixtures.makeExpenseGroup()],
                hasMore: true
            )
        )
    }

    func testHandleLoadNextPageWhenNoMorePagesDoesNotLoad() async {
        // Arrange
        await sut.fetchData()

        // Act
        await sut.handleLoadNextPage()

        // Assert
        XCTAssertFalse(repository.loadNextExpensesPageCalled)
    }
}

// MARK: - handleTapRetry

extension ExpesiesListInteractorTests {
    func testHandleTapRetryRefetchesFirstPage() async {
        // Arrange
        repository.refreshExpensesFirstPageThrowableError = TestError.any
        await sut.fetchData()
        repository.refreshExpensesFirstPageThrowableError = nil

        // Act
        await sut.handleTapRetry()

        // Assert
        XCTAssertEqual(repository.refreshExpensesFirstPageCallsCount, 2)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last, ExpesiesListFetchData(loadingState: .loaded, hasMore: false))
        XCTAssertEqual(analytics.trackScreenOpenCallsCount, 1)
    }
}
