import XCTest
@testable import Vault

final class CategoryProvidersTests: XCTestCase {
    func testSummaryProviderFetchCategoryMapsResponse() async throws {
        let service = CategorySummaryServiceSpy(
            getResult: .success(
                .init(
                    category: .init(
                        id: "cat-1",
                        name: "Food",
                        icon: "🍔",
                        color: "light_orange",
                        totalSpentUsd: 123.4
                    )
                )
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
        let sut = CategorySummaryProvider(
            categoriesService: service,
            currencyConversionService: UserCurrencyConversionService(
                userProfileStorageService: profileStorage
            )
        )

        let category = try await sut.fetchCategory(id: "cat-1")

        XCTAssertEqual(category.id, "cat-1")
        XCTAssertEqual(category.name, "Food")
        XCTAssertEqual(category.icon, "🍔")
        XCTAssertEqual(category.color, "light_orange")
        XCTAssertEqual(category.amount, 61.7)
        XCTAssertEqual(category.currency, "EUR")
        let requestedCategoryIDs = await service.requestedCategoryIDs()
        XCTAssertEqual(requestedCategoryIDs, ["cat-1"])
    }
}

extension CategoryProvidersTests {
    func testSummaryProviderMapsUnmappedCategoryName() async throws {
        let service = CategorySummaryServiceSpy(
            getResult: .success(
                .init(
                    category: .init(
                        id: "cat-1",
                        name: "Unmapped",
                        icon: "❓",
                        color: "light_blue",
                        totalSpentUsd: nil
                    )
                )
            )
        )
        let sut = CategorySummaryProvider(
            categoriesService: service,
            currencyConversionService: UserCurrencyConversionService(
                userProfileStorageService: UserProfileStorageSpy(profile: nil)
            )
        )

        let category = try await sut.fetchCategory(id: "cat-1")

        XCTAssertEqual(category.name, L10n.other)
        XCTAssertEqual(category.amount, .zero)
    }
}

extension CategoryProvidersTests {
    func testExpensesProviderFetchPageForwardsCategoryCursorAndLimit() async throws {
        let service = CategoryExpensesServiceSpy(
            listResult: .success(
                .init(
                    expenses: [
                        .init(
                            id: "exp-1",
                            title: "Coffee",
                            description: nil,
                            amount: 4.5,
                            currency: "USD",
                            category: "cat-1",
                            timeOfAdd: Date(timeIntervalSince1970: 100)
                        )
                    ],
                    nextCursor: "next-1",
                    hasMore: true
                )
            ),
            deleteResult: .success(())
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
        let sut = CategoryExpensesProvider(
            expensesService: service,
            currencyConversionService: UserCurrencyConversionService(
                userProfileStorageService: profileStorage
            )
        )

        let page = try await sut.fetchExpensesPage(
            categoryID: "cat-1",
            cursor: "cursor-1",
            limit: 20
        )

        XCTAssertEqual(page.expenses.count, 1)
        XCTAssertEqual(page.expenses.first?.description, "")
        XCTAssertEqual(page.expenses.first?.amount, 2.25)
        XCTAssertEqual(page.expenses.first?.currency, "EUR")
        XCTAssertEqual(page.nextCursor, "next-1")
        XCTAssertTrue(page.hasMore)
        let requestedParameters = await service.requestedListParameters()
        XCTAssertEqual(
            requestedParameters,
            [.init(category: "cat-1", cursor: "cursor-1", limit: 20)]
        )
    }
}

extension CategoryProvidersTests {
    func testExpensesProviderDeleteForwardsExpenseID() async throws {
        let service = CategoryExpensesServiceSpy(
            listResult: .success(
                .init(
                    expenses: [],
                    nextCursor: nil,
                    hasMore: false
                )
            ),
            deleteResult: .success(())
        )
        let sut = CategoryExpensesProvider(
            expensesService: service,
            currencyConversionService: UserCurrencyConversionService(
                userProfileStorageService: UserProfileStorageSpy(profile: nil)
            )
        )

        try await sut.deleteExpense(id: "exp-1")

        let requestedDeleteIDs = await service.requestedDeleteIDs()
        XCTAssertEqual(requestedDeleteIDs, ["exp-1"])
    }
}

private actor CategorySummaryServiceSpy: MainCategoriesContractServicing {
    private let getResult: Result<CategoryResponseDTO, Error>
    private var requestedIDs: [String] = []

    init(getResult: Result<CategoryResponseDTO, Error>) {
        self.getResult = getResult
    }

    func createCategory(_ request: CategoryCreateRequestDTO) async throws -> CategoryResponseDTO {
        throw StubError.any
    }

    func listCategories() async throws -> CategoriesResponseDTO {
        throw StubError.any
    }

    func getCategory(id: String) async throws -> CategoryResponseDTO {
        requestedIDs.append(id)
        return try getResult.get()
    }

    func deleteCategory(id: String) async throws {
        throw StubError.any
    }

    func requestedCategoryIDs() -> [String] {
        requestedIDs
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

private actor CategoryExpensesServiceSpy: MainExpensesContractServicing {
    private let listResult: Result<ExpensesListResponseDTO, Error>
    private let deleteResult: Result<Void, Error>
    private var listParametersHistory: [ExpensesListQueryParameters] = []
    private var deleteIDs: [String] = []

    init(
        listResult: Result<ExpensesListResponseDTO, Error>,
        deleteResult: Result<Void, Error>
    ) {
        self.listResult = listResult
        self.deleteResult = deleteResult
    }

    func createExpenses(_ request: ExpensesCreateRequestDTO) async throws -> ExpensesCreateResponseDTO {
        throw StubError.any
    }

    func listExpenses(parameters: ExpensesListQueryParameters) async throws -> ExpensesListResponseDTO {
        listParametersHistory.append(parameters)
        return try listResult.get()
    }

    func deleteExpense(id: String) async throws {
        deleteIDs.append(id)
        _ = try deleteResult.get()
    }

    func requestedListParameters() -> [ExpensesListQueryParameters] {
        listParametersHistory
    }

    func requestedDeleteIDs() -> [String] {
        deleteIDs
    }
}

private enum StubError: Error {
    case any
}
