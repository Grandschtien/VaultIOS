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
    func testFetchCategoriesUsesTotalSpentAndFallsBackToUsdWhenMissing() async throws {
        let categoriesService = CategoriesServiceSpy(
            listResult: .success(
                CategoriesResponseDTO(categories: [
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
        XCTAssertEqual(categories[0].currency, "EUR")
        XCTAssertEqual(categories[1].amount, 7.25)
        XCTAssertEqual(categories[1].currency, "USD")
        XCTAssertEqual(categories[1].name, "Другое")
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

private final class UserProfileStorageSpy: UserProfileStorageServiceProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var profile: UserProfileDefaults?

    init(profile: UserProfileDefaults?) {
        self.profile = profile
    }

    func saveProfile(_ profile: UserProfileDefaults) {
        lock.lock()
        self.profile = profile
        lock.unlock()
    }

    func loadProfile() -> UserProfileDefaults? {
        lock.lock()
        let value = profile
        lock.unlock()
        return value
    }

    func clearProfile() {
        lock.lock()
        profile = nil
        lock.unlock()
    }
}
