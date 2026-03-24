import XCTest
@testable import Vault

final class MainCategoriesProviderTests: XCTestCase {
    func testFetchCategoriesFetchesSummariesForFirstFourCategories() async throws {
        let categoriesService = CategoriesServiceSpy(
            listResult: .success(
                CategoriesResponseDTO(categories: [
                    .init(id: "cat-1", name: "Food", icon: "🍴", color: "light_orange"),
                    .init(id: "cat-2", name: "Transport", icon: "🚘", color: "light_blue"),
                    .init(id: "cat-3", name: "Leisure", icon: "🎬", color: "light_purple"),
                    .init(id: "cat-4", name: "Shopping", icon: "🛍", color: "light_pink"),
                    .init(id: "cat-5", name: "Health", icon: "💊", color: "light_red")
                ])
            )
        )

        let summaryService = SummaryServiceSpy(
            summaryByCategoryResult: [
                "cat-1": .success(.init(category: "cat-1", total: 10, currency: "USD", byCategory: nil)),
                "cat-2": .success(.init(category: "cat-2", total: 20, currency: "USD", byCategory: nil)),
                "cat-3": .success(.init(category: "cat-3", total: 30, currency: "USD", byCategory: nil)),
                "cat-4": .success(.init(category: "cat-4", total: 40, currency: "USD", byCategory: nil))
            ]
        )

        let sut = MainCategoriesProvider(
            categoriesService: categoriesService,
            summaryService: summaryService,
            cache: MainDataStoreCache()
        )

        let categories = try await sut.fetchCategories()
        let requestedCategoryIDs = await summaryService.requestedCategoryIDs()

        XCTAssertEqual(categories.count, 5)
        XCTAssertEqual(Set(requestedCategoryIDs), Set(["cat-1", "cat-2", "cat-3", "cat-4"]))
        XCTAssertEqual(categories[0].amount, 10)
        XCTAssertEqual(categories[3].amount, 40)
        XCTAssertEqual(categories[4].amount, 0)
    }
}

extension MainCategoriesProviderTests {
    func testFetchCategoriesUsesCacheOnSecondLoad() async throws {
        let categoriesService = CategoriesServiceSpy(
            listResult: .success(
                CategoriesResponseDTO(categories: [
                    .init(id: "cat-1", name: "Food", icon: "🍴", color: "light_orange"),
                    .init(id: "cat-2", name: "Transport", icon: "🚘", color: "light_blue"),
                    .init(id: "cat-3", name: "Leisure", icon: "🎬", color: "light_purple"),
                    .init(id: "cat-4", name: "Shopping", icon: "🛍", color: "light_pink")
                ])
            )
        )

        let summaryService = SummaryServiceSpy(
            summaryByCategoryResult: [
                "cat-1": .success(.init(category: "cat-1", total: 10, currency: "USD", byCategory: nil)),
                "cat-2": .success(.init(category: "cat-2", total: 20, currency: "USD", byCategory: nil)),
                "cat-3": .success(.init(category: "cat-3", total: 30, currency: "USD", byCategory: nil)),
                "cat-4": .success(.init(category: "cat-4", total: 40, currency: "USD", byCategory: nil))
            ]
        )

        let sut = MainCategoriesProvider(
            categoriesService: categoriesService,
            summaryService: summaryService,
            cache: MainDataStoreCache()
        )

        _ = try await sut.fetchCategories()
        _ = try await sut.fetchCategories()

        let requestedCategoryIDs = await summaryService.requestedCategoryIDs()
        XCTAssertEqual(requestedCategoryIDs.count, 4)
    }
}

extension MainCategoriesProviderTests {
    func testFetchCategoriesWhenCategorySummaryFailsKeepsCategoryData() async throws {
        let categoriesService = CategoriesServiceSpy(
            listResult: .success(
                CategoriesResponseDTO(categories: [
                    .init(id: "cat-1", name: "Food", icon: "🍴", color: "light_orange"),
                    .init(id: "cat-2", name: "Transport", icon: "🚘", color: "light_blue"),
                    .init(id: "cat-3", name: "Leisure", icon: "🎬", color: "light_purple"),
                    .init(id: "cat-4", name: "Shopping", icon: "🛍", color: "light_pink")
                ])
            )
        )

        let summaryService = SummaryServiceSpy(
            summaryByCategoryResult: [
                "cat-1": .success(.init(category: "cat-1", total: 10, currency: "USD", byCategory: nil)),
                "cat-2": .failure(StubError.any),
                "cat-3": .success(.init(category: "cat-3", total: 30, currency: "USD", byCategory: nil)),
                "cat-4": .failure(StubError.any)
            ]
        )

        let sut = MainCategoriesProvider(
            categoriesService: categoriesService,
            summaryService: summaryService,
            cache: MainDataStoreCache()
        )

        let categories = try await sut.fetchCategories()

        XCTAssertEqual(categories.count, 4)
        XCTAssertEqual(categories[0].name, "Food")
        XCTAssertEqual(categories[1].name, "Transport")
        XCTAssertEqual(categories[1].amount, .zero)
        XCTAssertEqual(categories[1].currency, "USD")
        XCTAssertEqual(categories[2].amount, 30)
    }
}

extension MainCategoriesProviderTests {
    func testFetchCategoriesMapsUnmappedNameToLocalizedValue() async throws {
        let categoriesService = CategoriesServiceSpy(
            listResult: .success(
                CategoriesResponseDTO(categories: [
                    .init(id: "cat-1", name: "Unmapped", icon: "📦", color: "light_gray")
                ])
            )
        )

        let summaryService = SummaryServiceSpy(
            summaryByCategoryResult: [
                "cat-1": .success(.init(category: "cat-1", total: 0, currency: "USD", byCategory: nil))
            ]
        )

        let sut = MainCategoriesProvider(
            categoriesService: categoriesService,
            summaryService: summaryService,
            cache: MainDataStoreCache()
        )

        let categories = try await sut.fetchCategories()

        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories[0].name, "Прочее")
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

private actor SummaryServiceSpy: MainSummaryContractServicing {
    private let summaryByCategoryResult: [String: Result<SummaryResponseDTO, Error>]
    private var requestedIDs: [String] = []

    init(summaryByCategoryResult: [String: Result<SummaryResponseDTO, Error>]) {
        self.summaryByCategoryResult = summaryByCategoryResult
    }

    func getSummary(parameters: SummaryQueryParameters) async throws -> SummaryResponseDTO {
        throw MainCategoriesProviderTests.StubError.any
    }

    func getSummaryByCategory(
        id: String,
        parameters: SummaryQueryParameters
    ) async throws -> SummaryResponseDTO {
        requestedIDs.append(id)

        if let result = summaryByCategoryResult[id] {
            return try result.get()
        }

        throw MainCategoriesProviderTests.StubError.any
    }

    func requestedCategoryIDs() -> [String] {
        requestedIDs
    }
}
