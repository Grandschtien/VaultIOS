import XCTest
@testable import Vylok

final class CategoriesListCategoriesProviderTests: XCTestCase {
    func testCachedCategoriesReturnsSavedValue() {
        let cache = MainDataStoreCache()
        let cachedCategories = [
            MainCategoryCardModel(
                id: "cat-1",
                name: "Food",
                icon: "🍴",
                color: "light_orange",
                amount: 10,
                currency: "USD"
            )
        ]
        cache.save(categories: cachedCategories)

        let sut = CategoriesListCategoriesProvider(
            categoriesService: MainCategoriesContractServicingMock(),
            cache: cache
        )

        XCTAssertEqual(sut.cachedCategories(), cachedCategories)
    }
}

extension CategoriesListCategoriesProviderTests {
    func testFetchCategoriesUsesTotalSpentAndFallsBackToUsdWhenMissing() async throws {
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesReturnValue = CategoriesResponseDTO(categories: [
            .init(
                id: "cat-1",
                name: "Food",
                icon: "🍴",
                color: "light_orange",
                totalSpent: 18.5,
                currency: "EUR"
            ),
            .init(
                id: "cat-2",
                name: "Unmapped",
                icon: "📦",
                color: "light_blue",
                totalSpentUsd: 7.25,
                totalSpent: nil,
                currency: "EUR"
            )
        ])
        let cache = MainDataStoreCache()
        let sut = CategoriesListCategoriesProvider(
            categoriesService: categoriesService,
            cache: cache
        )

        let categories = try await sut.fetchCategories()

        XCTAssertEqual(categories.count, 2)
        XCTAssertEqual(categories[0].amount, 18.5)
        XCTAssertEqual(categories[0].currency, "EUR")
        XCTAssertEqual(categories[1].amount, 7.25)
        XCTAssertEqual(categories[1].currency, "USD")
        XCTAssertEqual(categories[1].name, "Другое")
        XCTAssertEqual(cache.categories(), categories)
    }
}

extension CategoriesListCategoriesProviderTests {
    func testFetchCategoriesWhenServiceFailsRethrowsError() async {
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesThrowableError = TestError.any
        let sut = CategoriesListCategoriesProvider(
            categoriesService: categoriesService,
            cache: MainDataStoreCache()
        )

        do {
            _ = try await sut.fetchCategories()
            XCTFail("Expected throw")
        } catch {
            XCTAssertEqual(error as? TestError, .any)
        }
    }
}
