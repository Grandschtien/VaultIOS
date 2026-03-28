import XCTest
@testable import Vault

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
            categoriesService: CategoriesServiceSpy(listResult: .failure(StubError.any)),
            cache: cache
        )

        XCTAssertEqual(sut.cachedCategories(), cachedCategories)
    }
}

extension CategoriesListCategoriesProviderTests {
    func testFetchCategoriesMapsResponseAndSavesCache() async throws {
        let categoriesService = CategoriesServiceSpy(
            listResult: .success(
                CategoriesResponseDTO(categories: [
                    .init(
                        id: "cat-1",
                        name: "Food",
                        icon: "🍴",
                        color: "light_orange",
                        totalSpentUsd: 18.5
                    ),
                    .init(
                        id: "cat-2",
                        name: "Unmapped",
                        icon: "📦",
                        color: "light_blue",
                        totalSpentUsd: nil
                    )
                ])
            )
        )
        let cache = MainDataStoreCache()
        let sut = CategoriesListCategoriesProvider(
            categoriesService: categoriesService,
            cache: cache
        )

        let categories = try await sut.fetchCategories()

        XCTAssertEqual(categories.count, 2)
        XCTAssertEqual(categories[0].amount, 18.5)
        XCTAssertEqual(categories[1].amount, .zero)
        XCTAssertEqual(categories[1].name, "Прочее")
        XCTAssertEqual(cache.categories(), categories)
    }
}

extension CategoriesListCategoriesProviderTests {
    func testFetchCategoriesWhenServiceFailsRethrowsError() async {
        let sut = CategoriesListCategoriesProvider(
            categoriesService: CategoriesServiceSpy(listResult: .failure(StubError.any)),
            cache: MainDataStoreCache()
        )

        do {
            _ = try await sut.fetchCategories()
            XCTFail("Expected throw")
        } catch {
            XCTAssertNotNil(error as? StubError)
        }
    }
}

private extension CategoriesListCategoriesProviderTests {
    enum StubError: Error {
        case any
    }
}

private actor CategoriesServiceSpy: MainCategoriesContractServicing {
    private let listResult: Result<CategoriesResponseDTO, Error>

    init(listResult: Result<CategoriesResponseDTO, Error>) {
        self.listResult = listResult
    }

    func createCategory(_ request: CategoryCreateRequestDTO) async throws -> CategoryResponseDTO {
        throw CategoriesListCategoriesProviderTests.StubError.any
    }

    func listCategories() async throws -> CategoriesResponseDTO {
        try listResult.get()
    }

    func getCategory(id: String) async throws -> CategoryResponseDTO {
        throw CategoriesListCategoriesProviderTests.StubError.any
    }

    func deleteCategory(id: String) async throws {
        throw CategoriesListCategoriesProviderTests.StubError.any
    }
}
