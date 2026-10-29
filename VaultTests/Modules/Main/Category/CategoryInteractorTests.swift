import XCTest
@testable import Vylok

@MainActor
final class CategoryInteractorTests: XCTestCase {
    private var store: MainFlowDomainStore!
    private var observer: MainFlowDomainObserver!
    private var repository: MainFlowDomainRepositoryProtocolMock!

    override func setUp() {
        super.setUp()
        store = MainFlowDomainStore()
        observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        repository = MainFlowDomainRepositoryProtocolMock()
    }

    override func tearDown() {
        repository = nil
        observer = nil
        store = nil
        super.tearDown()
    }
}

extension CategoryInteractorTests {
    func testHandleTapEditCategoryRoutesToEditorWithCurrentCategoryID() async {
        stubRepository(
            refreshResults: [.failure(StubError.any)],
            nextPageResults: [],
            deleteResults: []
        )
        let router = CategoryRoutingLogicMock()
        let sut = makeSut(
            presenter: CategoryPresentationLogicMock(),
            router: router,
            repository: repository,
            observer: observer
        )

        await sut.handleTapEditCategory()

        XCTAssertEqual(router.openCategoryEditIdReceivedInvocations, ["cat-1"])
    }

    func testHandleTapEditCategoryIsUnavailableForOtherAndUnmapped() async {
        stubRepository(
            refreshResults: [.failure(StubError.any)],
            nextPageResults: [],
            deleteResults: []
        )
        let otherPresenter = CategoryPresentationLogicMock()
        let otherRouter = CategoryRoutingLogicMock()
        let otherSut = makeSut(
            presenter: otherPresenter,
            router: otherRouter,
            repository: repository,
            observer: observer,
            categoryName: L10n.other
        )

        await otherSut.fetchData()
        await otherSut.handleTapEditCategory()
        await waitForUpdates()

        XCTAssertEqual(otherPresenter.presentFetchedDataReceivedInvocations.last?.canEditCategory, false)
        XCTAssertTrue(otherRouter.openCategoryEditIdReceivedInvocations.isEmpty)

        stubRepository(
            refreshResults: [.failure(StubError.any)],
            nextPageResults: [],
            deleteResults: []
        )
        let unmappedRouter = CategoryRoutingLogicMock()
        let unmappedSut = makeSut(
            presenter: CategoryPresentationLogicMock(),
            router: unmappedRouter,
            repository: repository,
            observer: observer,
            categoryName: "Unmapped"
        )

        await unmappedSut.handleTapEditCategory()

        XCTAssertTrue(unmappedRouter.openCategoryEditIdReceivedInvocations.isEmpty)
    }

    func testFetchDataBuildsLoadedState() async {
        let initialPeriod = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 10),
            to: Date(timeIntervalSince1970: 20)
        )
        let presenter = CategoryPresentationLogicMock()
        stubRepository(
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
            router: CategoryRoutingLogicMock(),
            repository: repository,
            observer: observer,
            initialPeriod: initialPeriod
        )

        await sut.fetchData()
        await waitForUpdates()

        guard let first = presenter.presentFetchedDataReceivedInvocations.first,
              let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter updates")
        }

        assertStatus(first.loadingState, is: .loading)
        assertStatus(last.loadingState, is: .loaded)
        XCTAssertEqual(last.navigationTitle, "Food")
        XCTAssertEqual(last.fromDate, initialPeriod.from)
        XCTAssertEqual(last.toDate, initialPeriod.to)
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).count, 1)
        let requestedPeriods = requestedRefreshPeriods()
        XCTAssertEqual(requestedPeriods, [initialPeriod])
    }
}

extension CategoryInteractorTests {
    func testFetchDataWithCachedCurrentPeriodDetailUsesCacheWithoutRefresh() async {
        let initialPeriod = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 10),
            to: Date(timeIntervalSince1970: 20)
        )
        let presenter = CategoryPresentationLogicMock()
        stubRepository(
            refreshResults: [.failure(StubError.any)],
            nextPageResults: [],
            deleteResults: []
        )
        seedSnapshot(
            period: initialPeriod,
            payload: .init(
                category: makeCategory(amount: 10),
                expenses: [makeExpense(id: "exp-1", time: 100)],
                hasMore: false
            )
        )
        let sut = makeSut(
            presenter: presenter,
            router: CategoryRoutingLogicMock(),
            repository: repository,
            observer: observer,
            initialPeriod: initialPeriod
        )

        await sut.fetchData()
        await waitForUpdates()

        guard let first = presenter.presentFetchedDataReceivedInvocations.first,
              let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter updates")
        }

        assertStatus(first.loadingState, is: .loaded)
        XCTAssertTrue(first.hasResolvedCurrentPeriodContent)
        XCTAssertEqual(first.expenseGroups.flatMap(\.expenses).map(\.id), ["exp-1"])
        assertStatus(last.loadingState, is: .loaded)
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).map(\.id), ["exp-1"])
        let requestedPeriods = requestedRefreshPeriods()
        XCTAssertTrue(requestedPeriods.isEmpty)
    }

    func testHandleLoadNextPageAppendsExpenses() async {
        let initialPeriod = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 10),
            to: Date(timeIntervalSince1970: 20)
        )
        let presenter = CategoryPresentationLogicMock()
        stubRepository(
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
            router: CategoryRoutingLogicMock(),
            repository: repository,
            observer: observer,
            initialPeriod: initialPeriod
        )

        await sut.fetchData()
        await sut.handleLoadNextPage()
        await waitForUpdates()

        guard let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter update")
        }

        assertStatus(last.loadingState, is: .loaded)
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).count, 2)
        XCTAssertFalse(last.hasMore)
    }
}

extension CategoryInteractorTests {
    func testHandleDeleteExpenseFailureRestoresStateAndShowsError() async {
        let initialPeriod = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 10),
            to: Date(timeIntervalSince1970: 20)
        )
        let presenter = CategoryPresentationLogicMock()
        let router = CategoryRoutingLogicMock()
        stubRepository(
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
            observer: observer,
            initialPeriod: initialPeriod
        )

        await sut.fetchData()
        await sut.handleDeleteExpense(id: "exp-1")
        await waitForUpdates()

        guard let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter update")
        }

        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).count, 1)
        XCTAssertTrue(last.deletingExpenseIDs.isEmpty)
        XCTAssertEqual(router.presentErrorWithReceivedInvocations, [L10n.mainOverviewError])
    }
}

extension CategoryInteractorTests {
    func testFetchDataUsesSnapshotWhenPeriodMatchesByDayIgnoringTime() async {
        let initialPeriod = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 86_500),
            to: Date(timeIntervalSince1970: 172_799)
        )
        let cachedPeriod = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 100_000),
            to: Date(timeIntervalSince1970: 150_000)
        )
        let presenter = CategoryPresentationLogicMock()
        stubRepository(
            refreshResults: [.failure(StubError.any)],
            nextPageResults: [],
            deleteResults: []
        )
        seedSnapshot(
            period: cachedPeriod,
            payload: .init(
                category: makeCategory(amount: 10),
                expenses: [makeExpense(id: "exp-1", time: 100)],
                hasMore: false
            )
        )
        let sut = makeSut(
            presenter: presenter,
            router: CategoryRoutingLogicMock(),
            repository: repository,
            observer: observer,
            initialPeriod: initialPeriod
        )

        await sut.fetchData()
        await waitForUpdates()

        guard let first = presenter.presentFetchedDataReceivedInvocations.first,
              let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter updates")
        }

        assertStatus(first.loadingState, is: .loaded)
        XCTAssertTrue(first.hasResolvedCurrentPeriodContent)
        XCTAssertEqual(first.expenseGroups.flatMap(\.expenses).map(\.id), ["exp-1"])
        assertStatus(last.loadingState, is: .loaded)
        let requestedPeriods = requestedRefreshPeriods()
        XCTAssertTrue(requestedPeriods.isEmpty)
    }

    func testFetchDataUpdatesOpenedCategoryWhenSnapshotChanges() async {
        let initialPeriod = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 10),
            to: Date(timeIntervalSince1970: 20)
        )
        let presenter = CategoryPresentationLogicMock()
        stubRepository(
            refreshResults: [
                .success(
                    .init(
                        category: makeCategory(amount: 10),
                        expenses: [makeExpense(id: "exp-1", time: 200)],
                        hasMore: false
                    )
                )
            ],
            nextPageResults: [],
            deleteResults: []
        )
        let sut = makeSut(
            presenter: presenter,
            router: CategoryRoutingLogicMock(),
            repository: repository,
            observer: observer,
            initialPeriod: initialPeriod
        )

        await sut.fetchData()
        let snapshotPresented = presentationExpectation(on: presenter) { data in
            data.category?.amount == 14
        }

        seedSnapshot(
            period: initialPeriod,
            payload: .init(
                category: makeCategory(amount: 14),
                expenses: [
                    makeExpense(id: "exp-2", time: 300),
                    makeExpense(id: "exp-1", time: 200)
                ],
                hasMore: false
            )
        )
        await fulfillment(of: [snapshotPresented], timeout: 1)

        guard let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter update")
        }

        XCTAssertEqual(last.category?.amount, 14)
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).map(\.id), ["exp-2", "exp-1"])
    }

    func testFetchDataIgnoresStaleSnapshotFromDifferentPeriod() async {
        let initialPeriod = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 100),
            to: Date(timeIntervalSince1970: 200)
        )
        let stalePeriod = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 200_000),
            to: Date(timeIntervalSince1970: 250_000)
        )
        let presenter = CategoryPresentationLogicMock()
        stubRepository(
            refreshResults: [.failure(StubError.any)],
            nextPageResults: [],
            deleteResults: []
        )

        seedSnapshot(
            period: stalePeriod,
            payload: .init(
                category: makeCategory(amount: 10),
                expenses: [makeExpense(id: "exp-1", time: 100)],
                hasMore: false
            )
        )

        let sut = makeSut(
            presenter: presenter,
            router: CategoryRoutingLogicMock(),
            repository: repository,
            observer: observer,
            initialPeriod: initialPeriod
        )
        let failurePresented = presentationExpectation(on: presenter) { [unowned self] data in
            isStatus(data.loadingState, .failed)
        }

        await sut.fetchData()
        await fulfillment(of: [failurePresented], timeout: 1)

        guard let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter update")
        }

        assertStatus(last.loadingState, is: .failed)
        XCTAssertNil(last.category)
        XCTAssertTrue(last.expenseGroups.isEmpty)
    }

    func testHandleLoadNextPageFailureKeepsExistingExpensesAndShowsError() async {
        let initialPeriod = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 10),
            to: Date(timeIntervalSince1970: 20)
        )
        let presenter = CategoryPresentationLogicMock()
        let router = CategoryRoutingLogicMock()
        stubRepository(
            refreshResults: [
                .success(
                    .init(
                        category: makeCategory(amount: 10),
                        expenses: [makeExpense(id: "exp-1", time: 200)],
                        hasMore: true
                    )
                )
            ],
            nextPageResults: [.failure(StubError.any)],
            deleteResults: []
        )
        let sut = makeSut(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            initialPeriod: initialPeriod
        )

        await sut.fetchData()
        await sut.handleLoadNextPage()
        await waitForUpdates()

        guard let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter update")
        }

        assertStatus(last.loadingState, is: .loaded)
        XCTAssertEqual(last.expenseGroups.flatMap(\.expenses).map(\.id), ["exp-1"])
        XCTAssertEqual(router.presentErrorWithReceivedInvocations, [L10n.mainOverviewError])
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
        observer: MainFlowDomainObserverProtocol,
        categoryName: String? = "Food",
        initialPeriod: MainSummaryPeriod = .init(
            from: Date(timeIntervalSince1970: 1),
            to: Date(timeIntervalSince1970: 2)
        )
    ) -> CategoryInteractor {
        CategoryInteractor(
            categoryID: "cat-1",
            categoryName: categoryName,
            initialPeriod: initialPeriod,
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            calendar: makeCalendar()
        )
    }

    func makeExpense(
        id: String,
        category: String = "cat-1",
        time: TimeInterval
    ) -> MainExpenseModel {
        MainExpenseModel(
            id: id,
            title: "Coffee",
            description: "Morning",
            amount: 4.5,
            currency: "USD",
            category: category,
            timeOfAdd: Date(timeIntervalSince1970: time)
        )
    }

    func makeCategory(
        id: String = "cat-1",
        name: String = "Food",
        amount: Double
    ) -> MainCategoryCardModel {
        MainCategoryCardModel(
            id: id,
            name: name,
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

    func presentationExpectation(
        on presenter: CategoryPresentationLogicMock,
        where predicate: @escaping (CategoryFetchData) -> Bool
    ) -> XCTestExpectation {
        let expectation = expectation(description: "Presenter received expected data")
        expectation.assertForOverFulfill = false
        presenter.presentFetchedDataClosure = { data in
            guard predicate(data) else {
                return
            }

            expectation.fulfill()
        }
        return expectation
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

private extension CategoryInteractorTests {
    struct CategoryPayload {
        let category: MainCategoryCardModel
        let expenses: [MainExpenseModel]
        let hasMore: Bool
    }

    func stubRepository(
        refreshResults: [Result<CategoryPayload, Error>],
        nextPageResults: [Result<CategoryPayload, Error>],
        deleteResults: [Result<Void, Error>]
    ) {
        let store: MainFlowDomainStore = store
        let observer: MainFlowDomainObserver = observer
        repository.refreshCategoryFirstPageIdFromDateToDateClosure = { [unowned repository = repository!] _, fromDate, toDate in
            let index = min(repository.refreshCategoryFirstPageIdFromDateToDateCallsCount - 1, max(refreshResults.count - 1, .zero))
            let payload = try refreshResults[index].get()
            let period = fromDate.flatMap { from in toDate.map { MainSummaryPeriod(from: from, to: $0) } }
            Self.apply(payload: payload, period: period, replaceExpenses: true, store: store, observer: observer)
        }
        repository.loadNextCategoryPageIdClosure = { [unowned repository = repository!] id in
            let index = min(repository.loadNextCategoryPageIdCallsCount - 1, max(nextPageResults.count - 1, .zero))
            let payload = try nextPageResults[index].get()
            let period = store.snapshot().categoryPeriods[id] ?? nil
            Self.apply(payload: payload, period: period, replaceExpenses: false, store: store, observer: observer)
        }
        repository.deleteExpenseIdClosure = { [unowned repository = repository!] id in
            let index = min(repository.deleteExpenseIdCallsCount - 1, max(deleteResults.count - 1, .zero))
            let previousState = store.snapshot()
            store.update { state in
                state.pendingDeletedExpenseIDs.insert(id)
                state.categoryExpenseIDs["cat-1"]?.removeAll { $0 == id }
            }
            observer.publishAll(from: store)

            do {
                _ = try deleteResults[index].get()
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
    }

    func seedSnapshot(period: MainSummaryPeriod, payload: CategoryPayload) {
        Self.apply(payload: payload, period: period, replaceExpenses: true, store: store, observer: observer)
    }

    func requestedRefreshPeriods() -> [MainSummaryPeriod?] {
        repository.refreshCategoryFirstPageIdFromDateToDateReceivedInvocations.map { invocation in
            invocation.fromDate.flatMap { from in invocation.toDate.map { MainSummaryPeriod(from: from, to: $0) } }
        }
    }

    nonisolated static func apply(
        payload: CategoryPayload,
        period: MainSummaryPeriod?,
        replaceExpenses: Bool,
        store: MainFlowDomainStore,
        observer: MainFlowDomainObserver
    ) {
        store.update { state in
            state.categoryDetailsByID[payload.category.id] = payload.category
            state.categoryPeriods[payload.category.id] = period
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

private func makeCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}
