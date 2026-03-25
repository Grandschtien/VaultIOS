import XCTest
@testable import Vault

final class ExpesiesListCategoriesProviderTests: XCTestCase {
    func testFetchCategoriesMapsResponse() async throws {
        let service = ExpesiesListCategoriesServiceSpy(
            listResult: .success(
                .init(
                    categories: [
                        .init(
                            id: "cat-1",
                            name: "Food",
                            icon: "🍴",
                            color: "light_orange",
                            totalSpentUsd: 25
                        ),
                        .init(
                            id: "cat-2",
                            name: "Transport",
                            icon: "🚗",
                            color: "light_blue",
                            totalSpentUsd: 10
                        )
                    ]
                )
            )
        )
        let sut = ExpesiesListCategoriesProvider(categoriesService: service)

        let categories = try await sut.fetchCategories()

        XCTAssertEqual(categories.count, 2)
        XCTAssertEqual(categories[0].id, "cat-1")
        XCTAssertEqual(categories[0].icon, "🍴")
        XCTAssertEqual(categories[1].name, "Transport")
        XCTAssertEqual(categories[1].color, "light_blue")
    }

    func testFetchCategoriesWhenServiceFailsRethrows() async {
        let service = ExpesiesListCategoriesServiceSpy(
            listResult: .failure(StubError.any)
        )
        let sut = ExpesiesListCategoriesProvider(categoriesService: service)

        do {
            _ = try await sut.fetchCategories()
            XCTFail("Expected throw")
        } catch {
            XCTAssertNotNil(error as? StubError)
        }
    }
}

private actor ExpesiesListCategoriesServiceSpy: MainCategoriesContractServicing {
    private let listResult: Result<CategoriesResponseDTO, Error>

    init(listResult: Result<CategoriesResponseDTO, Error>) {
        self.listResult = listResult
    }

    func createCategory(_ request: CategoryCreateRequestDTO) async throws -> CategoryResponseDTO {
        throw StubError.any
    }

    func listCategories() async throws -> CategoriesResponseDTO {
        try listResult.get()
    }

    func getCategory(id: String) async throws -> CategoryResponseDTO {
        throw StubError.any
    }

    func deleteCategory(id: String) async throws {
        throw StubError.any
    }
}

private enum StubError: Error {
    case any
}
