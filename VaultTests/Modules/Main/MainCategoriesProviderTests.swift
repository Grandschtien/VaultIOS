import XCTest
@testable import Vault

final class MainCategoriesProviderTests: XCTestCase {
    func testFetchCategoriesMapsTotalSpentUsdIntoAmountForEachCategory() async throws {
        let categoriesService = CategoriesServiceSpy(
            listResult: .success(
                CategoriesResponseDTO(categories: [
                    .init(
                        id: "cat-1",
                        name: "Food",
                        icon: "🍴",
                        color: "light_orange",
                        totalSpentUsd: 10
                    ),
                    .init(
                        id: "cat-2",
                        name: "Transport",
                        icon: "🚘",
                        color: "light_blue",
                        totalSpentUsd: 25.4
                    ),
                    .init(
                        id: "cat-3",
                        name: "Leisure",
                        icon: "🎬",
                        color: "light_purple",
                        totalSpentUsd: 0
                    )
                ])
            )
        )
        let sut = MainCategoriesProvider(categoriesService: categoriesService)

        let categories = try await sut.fetchCategories()

        XCTAssertEqual(categories.count, 3)
        XCTAssertEqual(categories[0].amount, 10)
        XCTAssertEqual(categories[1].amount, 25.4)
        XCTAssertEqual(categories[2].amount, 0)
        XCTAssertTrue(categories.allSatisfy { $0.currency == "USD" })
    }
}

extension MainCategoriesProviderTests {
    func testFetchCategoriesUsesZeroAmountWhenTotalSpentUsdIsMissing() async throws {
        let categoriesService = CategoriesServiceSpy(
            listResult: .success(
                CategoriesResponseDTO(categories: [
                    .init(
                        id: "cat-1",
                        name: "Food",
                        icon: "🍴",
                        color: "light_orange",
                        totalSpentUsd: nil
                    )
                ])
            )
        )
        let sut = MainCategoriesProvider(categoriesService: categoriesService)

        let categories = try await sut.fetchCategories()

        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories[0].amount, .zero)
    }
}

extension MainCategoriesProviderTests {
    func testFetchCategoriesMapsUnmappedNameToLocalizedValue() async throws {
        let categoriesService = CategoriesServiceSpy(
            listResult: .success(
                CategoriesResponseDTO(categories: [
                    .init(
                        id: "cat-1",
                        name: "Unmapped",
                        icon: "📦",
                        color: "light_gray",
                        totalSpentUsd: 0
                    )
                ])
            )
        )
        let sut = MainCategoriesProvider(categoriesService: categoriesService)

        let categories = try await sut.fetchCategories()

        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories[0].name, "Прочее")
    }
}

extension MainCategoriesProviderTests {
    func testFetchCategoriesWhenServiceFailsRethrowsError() async {
        let categoriesService = CategoriesServiceSpy(listResult: .failure(StubError.any))
        let sut = MainCategoriesProvider(categoriesService: categoriesService)

        do {
            _ = try await sut.fetchCategories()
            XCTFail("Expected throw")
        } catch {
            XCTAssertNotNil(error as? StubError)
        }
    }
}

private extension MainCategoriesProviderTests {
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
        throw MainCategoriesProviderTests.StubError.any
    }

    func listCategories() async throws -> CategoriesResponseDTO {
        try listResult.get()
    }

    func getCategory(id: String) async throws -> CategoryResponseDTO {
        throw MainCategoriesProviderTests.StubError.any
    }

    func deleteCategory(id: String) async throws {
        throw MainCategoriesProviderTests.StubError.any
    }
}
