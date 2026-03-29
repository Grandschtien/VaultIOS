import XCTest
@testable import Vault

@MainActor
final class CategoriesListInteractorTests: XCTestCase {
    func testFetchDataWithoutCacheLoadsFreshCategories() async {
        let presenter = CategoriesListPresenterSpy()
        let sut = CategoriesListInteractor(
            presenter: presenter,
            router: CategoriesListRouterSpy(),
            categoriesProvider: CategoriesListProviderStub(
                cachedCategories: nil,
                fetchResult: .success([
                    .init(
                        id: "cat-1",
                        name: "Food",
                        icon: "🍴",
                        color: "light_orange",
                        amount: 12.5,
                        currency: "USD"
                    )
                ])
            )
        )

        await sut.fetchData()

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
    func testFetchDataWithCacheAndRefreshFailureKeepsCachedState() async {
        let presenter = CategoriesListPresenterSpy()
        let cachedCategories = [
            MainCategoryCardModel(
                id: "cat-1",
                name: "Food",
                icon: "🍴",
                color: "light_orange",
                amount: 5,
                currency: "USD"
            )
        ]
        let sut = CategoriesListInteractor(
            presenter: presenter,
            router: CategoriesListRouterSpy(),
            categoriesProvider: CategoriesListProviderStub(
                cachedCategories: cachedCategories,
                fetchResult: .failure(StubError.any)
            )
        )

        await sut.fetchData()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter updates")
        }

        assertStatus(last.loadingState, is: .loaded)
        XCTAssertEqual(last.categories, cachedCategories)

        let hasFailedState = presenter.presentedData.contains {
            if case .failed = $0.loadingState {
                return true
            }

            return false
        }
        XCTAssertFalse(hasFailedState)
    }
}

extension CategoriesListInteractorTests {
    func testFetchDataWithoutCacheAndRefreshFailureBuildsFailedState() async {
        let presenter = CategoriesListPresenterSpy()
        let sut = CategoriesListInteractor(
            presenter: presenter,
            router: CategoriesListRouterSpy(),
            categoriesProvider: CategoriesListProviderStub(
                cachedCategories: nil,
                fetchResult: .failure(StubError.any)
            )
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
}

extension CategoriesListInteractorTests {
    func testHandleTapCategoryRoutesToCategoryScreen() async {
        let router = CategoriesListRouterSpy()
        let sut = CategoriesListInteractor(
            presenter: CategoriesListPresenterSpy(),
            router: router,
            categoriesProvider: CategoriesListProviderStub(
                cachedCategories: nil,
                fetchResult: .success([])
            )
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
}

private extension CategoriesListInteractorTests {
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

private final class CategoriesListProviderStub: CategoriesListCategoriesProviding, @unchecked Sendable {
    private let cachedValue: [MainCategoryCardModel]?
    private let fetchResult: Result<[MainCategoryCardModel], Error>

    init(
        cachedCategories: [MainCategoryCardModel]?,
        fetchResult: Result<[MainCategoryCardModel], Error>
    ) {
        self.cachedValue = cachedCategories
        self.fetchResult = fetchResult
    }

    func cachedCategories() -> [MainCategoryCardModel]? {
        cachedValue
    }

    func fetchCategories() async throws -> [MainCategoryCardModel] {
        try fetchResult.get()
    }
}
