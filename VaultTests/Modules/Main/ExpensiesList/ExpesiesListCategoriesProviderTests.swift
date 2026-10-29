import XCTest
@testable import Vylok

final class ExpesiesListCategoriesProviderTests: XCTestCase {
    func testFetchCategoriesMapsResponse() async throws {
        let service = MainCategoriesContractServicingMock()
        service.listCategoriesReturnValue = .init(
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
        let sut = ExpesiesListCategoriesProvider(categoriesService: service)

        let categories = try await sut.fetchCategories()

        XCTAssertEqual(categories.count, 2)
        XCTAssertEqual(categories[0].id, "cat-1")
        XCTAssertEqual(categories[0].icon, "🍴")
        XCTAssertEqual(categories[1].name, "Transport")
        XCTAssertEqual(categories[1].color, "light_blue")
    }

    func testFetchCategoriesWhenServiceFailsRethrows() async {
        let service = MainCategoriesContractServicingMock()
        service.listCategoriesThrowableError = TestError.any
        let sut = ExpesiesListCategoriesProvider(categoriesService: service)

        do {
            _ = try await sut.fetchCategories()
            XCTFail("Expected throw")
        } catch {
            XCTAssertEqual(error as? TestError, .any)
        }
    }
}
