import XCTest
@testable import Vylok

final class CategoriesListInteractorTests: XCTestCase {
    private var presenter: CategoriesListPresentationLogicMock!
    private var router: CategoriesListRoutingLogicMock!
    private var repository: MainFlowDomainRepositoryProtocolMock!
    private var observer: MainFlowDomainObserverProtocolMock!

    override func setUp() {
        super.setUp()
        presenter = CategoriesListPresentationLogicMock()
        router = CategoriesListRoutingLogicMock()
        repository = MainFlowDomainRepositoryProtocolMock()
        observer = MainFlowDomainObserverProtocolMock()
        observer.subscribeCategoriesReturnValue = AsyncStream { _ in }
    }

    override func tearDown() {
        observer = nil
        repository = nil
        router = nil
        presenter = nil
        super.tearDown()
    }
}

// MARK: - fetchData

extension CategoriesListInteractorTests {
    func testFetchDataWhenRefreshSucceedsPresentsLoadingThenFreshCategories() async {
        // Arrange
        let sut = CategoriesListInteractor(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer
        )
        observer.currentCategoriesSnapshotReturnValue = MainFlowCategoriesSnapshot(
            categories: [MainModelFixtures.makeCategoryCard(amount: 12.5)]
        )

        // Act
        await sut.fetchData()

        // Assert
        XCTAssertEqual(repository.refreshCategoriesCallsCount, 1)
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                CategoriesListFetchData(loadingState: .loading),
                CategoriesListFetchData(
                    loadingState: .loaded,
                    categories: [MainModelFixtures.makeCategoryCard(amount: 12.5)]
                )
            ]
        )
    }

    func testFetchDataWhenRefreshFailsWithoutCategoriesPresentsError() async {
        // Arrange
        let sut = CategoriesListInteractor(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer
        )
        repository.refreshCategoriesThrowableError = TestError.any

        // Act
        await sut.fetchData()

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                CategoriesListFetchData(loadingState: .loading),
                CategoriesListFetchData(
                    loadingState: .failed(.undelinedError(description: TestError.any.localizedDescription))
                )
            ]
        )
    }

    func testFetchDataWhenSnapshotArrivesBeforeRefreshFailsKeepsLoadedCategories() async {
        // Arrange
        let sut = CategoriesListInteractor(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer
        )
        let (stream, continuation) = AsyncStream.makeStream(of: MainFlowCategoriesSnapshot.self)
        observer.subscribeCategoriesReturnValue = stream
        let snapshotPresented = expectation(description: "Snapshot presented")
        presenter.presentFetchedDataClosure = { data in
            if data.loadingState == .loaded {
                snapshotPresented.fulfill()
            }
        }
        repository.refreshCategoriesClosure = { [weak self] in
            continuation.yield(MainFlowCategoriesSnapshot(categories: [MainModelFixtures.makeCategoryCard(amount: 5)]))
            await self?.fulfillment(of: [snapshotPresented], timeout: 1.0)
            throw TestError.any
        }

        // Act
        await sut.fetchData()

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                CategoriesListFetchData(loadingState: .loading),
                CategoriesListFetchData(
                    loadingState: .loaded,
                    categories: [MainModelFixtures.makeCategoryCard(amount: 5)]
                )
            ]
        )
    }
}

// MARK: - handleTapCategory

extension CategoriesListInteractorTests {
    func testHandleTapCategoryOpensCategoryScreen() async {
        // Arrange
        let sut = CategoriesListInteractor(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer
        )

        // Act
        await sut.handleTapCategory(id: "cat-1", name: "Food")

        // Assert
        let arguments = router.openCategoryIdNameReceivedArguments
        XCTAssertEqual(router.openCategoryIdNameCallsCount, 1)
        XCTAssertTrue(arguments.map { $0 == (id: "cat-1", name: "Food") } ?? false)
    }
}
