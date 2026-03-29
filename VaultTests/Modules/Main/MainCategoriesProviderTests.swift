import XCTest
@testable import Vault

final class MainCategoriesProviderTests: XCTestCase {
    func testFetchCategoriesConvertsAmountAndUsesProfileCurrency() async throws {
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
        let profileStorage = UserProfileStorageSpy(
            profile: .init(
                userId: "user-1",
                email: "user@example.com",
                name: "Test User",
                currency: "EUR",
                language: "en-US",
                currencyRate: 2.0
            )
        )
        let sut = MainCategoriesProvider(
            categoriesService: categoriesService,
            cache: MainDataStoreCache(),
            currencyConversionService: UserCurrencyConversionService(
                userProfileStorageService: profileStorage
            )
        )

        let categories = try await sut.fetchCategories()

        XCTAssertEqual(categories.count, 3)
        XCTAssertEqual(categories[0].amount, 5.0)
        XCTAssertEqual(categories[1].amount, 12.7)
        XCTAssertEqual(categories[2].amount, 0)
        XCTAssertTrue(categories.allSatisfy { $0.currency == "EUR" })
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
        let profileStorage = UserProfileStorageSpy(
            profile: .init(
                userId: "user-1",
                email: "user@example.com",
                name: "Test User",
                currency: "USD",
                language: "en-US",
                currencyRate: 1.0
            )
        )
        let sut = MainCategoriesProvider(
            categoriesService: categoriesService,
            cache: MainDataStoreCache(),
            currencyConversionService: UserCurrencyConversionService(
                userProfileStorageService: profileStorage
            )
        )

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
        let profileStorage = UserProfileStorageSpy(profile: nil)
        let sut = MainCategoriesProvider(
            categoriesService: categoriesService,
            cache: MainDataStoreCache(),
            currencyConversionService: UserCurrencyConversionService(
                userProfileStorageService: profileStorage
            )
        )

        let categories = try await sut.fetchCategories()

        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories[0].name, "Прочее")
    }
}

extension MainCategoriesProviderTests {
    func testFetchCategoriesSavesLoadedCategoriesToCache() async throws {
        let categoriesService = CategoriesServiceSpy(
            listResult: .success(
                CategoriesResponseDTO(categories: [
                    .init(
                        id: "cat-1",
                        name: "Food",
                        icon: "🍴",
                        color: "light_orange",
                        totalSpentUsd: 14.7
                    )
                ])
            )
        )
        let cache = MainDataStoreCache()
        let profileStorage = UserProfileStorageSpy(
            profile: .init(
                userId: "user-1",
                email: "user@example.com",
                name: "Test User",
                currency: "KZT",
                language: "ru",
                currencyRate: 2.0
            )
        )
        let sut = MainCategoriesProvider(
            categoriesService: categoriesService,
            cache: cache,
            currencyConversionService: UserCurrencyConversionService(
                userProfileStorageService: profileStorage
            )
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
                    amount: 7.35,
                    currency: "KZT"
                )
            ]
        )
    }
}

extension MainCategoriesProviderTests {
    func testFetchCategoriesWhenServiceFailsRethrowsError() async {
        let categoriesService = CategoriesServiceSpy(listResult: .failure(StubError.any))
        let sut = MainCategoriesProvider(
            categoriesService: categoriesService,
            cache: MainDataStoreCache(),
            currencyConversionService: UserCurrencyConversionService(
                userProfileStorageService: UserProfileStorageSpy(profile: nil)
            )
        )

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
