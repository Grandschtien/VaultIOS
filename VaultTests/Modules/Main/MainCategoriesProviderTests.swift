import XCTest
@testable import Vylok

final class MainCategoriesProviderTests: XCTestCase {
    func testFetchCategoriesUsesResponseAmountAndCurrency() async throws {
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesReturnValue = CategoriesResponseDTO(categories: [
            .init(
                id: "cat-1",
                name: "Food",
                icon: "🍴",
                color: "light_orange",
                totalSpent: 10,
                currency: "EUR"
            ),
            .init(
                id: "cat-2",
                name: "Transport",
                icon: "🚘",
                color: "light_blue",
                totalSpent: 25.4,
                currency: "EUR"
            ),
            .init(
                id: "cat-3",
                name: "Leisure",
                icon: "🎬",
                color: "light_purple",
                totalSpent: 0,
                currency: "EUR"
            )
        ])
        let sut = MainCategoriesProvider(
            categoriesService: categoriesService,
            cache: MainDataStoreCache()
        )

        let categories = try await sut.fetchCategories()

        XCTAssertEqual(categories.count, 3)
        XCTAssertEqual(categories[0].amount, 10)
        XCTAssertEqual(categories[1].amount, 25.4)
        XCTAssertEqual(categories[2].amount, 0)
        XCTAssertTrue(categories.allSatisfy { $0.currency == "EUR" })
    }
}

extension MainCategoriesProviderTests {
    func testFetchCategoriesFallsBackToUsdWhenTotalSpentIsMissing() async throws {
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesReturnValue = CategoriesResponseDTO(categories: [
            .init(
                id: "cat-1",
                name: "Food",
                icon: "🍴",
                color: "light_orange",
                totalSpentUsd: 12.5,
                currency: "KZT"
            )
        ])
        let sut = MainCategoriesProvider(
            categoriesService: categoriesService,
            cache: MainDataStoreCache()
        )

        let categories = try await sut.fetchCategories()

        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories[0].amount, 12.5)
        XCTAssertEqual(categories[0].currency, "USD")
    }
}

extension MainCategoriesProviderTests {
    func testFetchCategoriesMapsUnmappedNameToLocalizedValue() async throws {
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesReturnValue = CategoriesResponseDTO(categories: [
            .init(
                id: "cat-1",
                name: "Unmapped",
                icon: "📦",
                color: "light_gray",
                totalSpentUsd: 0
            )
        ])
        let sut = MainCategoriesProvider(
            categoriesService: categoriesService,
            cache: MainDataStoreCache()
        )

        let categories = try await sut.fetchCategories()

        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories[0].name, "Другое")
    }
}

extension MainCategoriesProviderTests {
    func testFetchCategoriesSavesLoadedCategoriesToCache() async throws {
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesReturnValue = CategoriesResponseDTO(categories: [
            .init(
                id: "cat-1",
                name: "Food",
                icon: "🍴",
                color: "light_orange",
                totalSpent: 14.7,
                currency: "KZT"
            )
        ])
        let cache = MainDataStoreCache()
        let sut = MainCategoriesProvider(
            categoriesService: categoriesService,
            cache: cache
        )

        _ = try await sut.fetchCategories()

        XCTAssertEqual(
            cache.categories(),
            [
                MainCategoryCardModel(
                    id: "cat-1",
                    name: "Food",
                    icon: "🍴",
                    color: "light_orange",
                    amount: 14.7,
                    currency: "KZT"
                )
            ]
        )
    }
}

extension MainCategoriesProviderTests {
    func testFetchCategoriesWhenServiceFailsRethrowsError() async {
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesThrowableError = TestError.any
        let sut = MainCategoriesProvider(
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
