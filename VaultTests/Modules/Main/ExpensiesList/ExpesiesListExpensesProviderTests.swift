import XCTest
@testable import Vault

final class ExpesiesListExpensesProviderTests: XCTestCase {
    func testFetchExpensesPageForwardsCursorAndLimit() async throws {
        let service = ExpesiesListExpensesServiceSpy(
            listResult: .success(
                .init(
                    expenses: [makeExpense(id: "expense-1", description: "Description")],
                    nextCursor: "cursor-2",
                    hasMore: true
                )
            )
        )
        let sut = ExpesiesListExpensesProvider(
            expensesService: service,
            currencyConversionService: UserCurrencyConversionService(
                userProfileStorageService: UserProfileStorageSpy(profile: nil)
            )
        )

        let page = try await sut.fetchExpensesPage(cursor: "cursor-1", limit: 20)
        let requestedParameters = await service.requestedParameters()

        XCTAssertEqual(requestedParameters, [.init(cursor: "cursor-1", limit: 20)])
        XCTAssertEqual(page.nextCursor, "cursor-2")
        XCTAssertTrue(page.hasMore)
    }
}

extension ExpesiesListExpensesProviderTests {
    func testFetchExpensesPageMapsNilDescriptionToEmptyString() async throws {
        let service = ExpesiesListExpensesServiceSpy(
            listResult: .success(
                .init(
                    expenses: [makeExpense(id: "expense-1", description: nil)],
                    nextCursor: nil,
                    hasMore: false
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
        let sut = ExpesiesListExpensesProvider(
            expensesService: service,
            currencyConversionService: UserCurrencyConversionService(
                userProfileStorageService: profileStorage
            )
        )

        let page = try await sut.fetchExpensesPage(cursor: String?.none, limit: 20)

        XCTAssertEqual(page.expenses.count, 1)
        XCTAssertEqual(page.expenses.first?.description, "")
        XCTAssertEqual(page.expenses.first?.amount, 2.25)
        XCTAssertEqual(page.expenses.first?.currency, "EUR")
        XCTAssertNil(page.nextCursor)
        XCTAssertFalse(page.hasMore)
    }

    func testFetchExpensesPageWhenServiceFailsRethrows() async {
        let service = ExpesiesListExpensesServiceSpy(
            listResult: .failure(StubError.any)
        )
        let sut = ExpesiesListExpensesProvider(
            expensesService: service,
            currencyConversionService: UserCurrencyConversionService(
                userProfileStorageService: UserProfileStorageSpy(profile: nil)
            )
        )

        do {
            _ = try await sut.fetchExpensesPage(cursor: nil, limit: 20)
            XCTFail("Expected throw")
        } catch {
            XCTAssertNotNil(error as? StubError)
        }
    }

    func testFetchExpensesPageShowsOriginalAmountWhenOriginalCurrencyMatchesPreferredCurrency() async throws {
        let service = ExpesiesListExpensesServiceSpy(
            listResult: .success(
                .init(
                    expenses: [
                        ExpenseDTO(
                            id: "expense-1",
                            title: "Coffee",
                            description: "Description",
                            amount: 2.62,
                            currency: "USD",
                            originalAmount: 200,
                            originalCurrency: "RUB",
                            category: "cat-1",
                            timeOfAdd: Date(timeIntervalSince1970: 1_700_000_000)
                        )
                    ],
                    nextCursor: nil,
                    hasMore: false
                )
            )
        )
        let profileStorage = UserProfileStorageSpy(
            profile: .init(
                userId: "user-1",
                email: "user@example.com",
                name: "Test User",
                currency: "RUB",
                language: "ru",
                currencyRate: 76.34
            )
        )
        let sut = ExpesiesListExpensesProvider(
            expensesService: service,
            currencyConversionService: UserCurrencyConversionService(
                userProfileStorageService: profileStorage
            )
        )

        let page = try await sut.fetchExpensesPage(cursor: nil, limit: 20)

        XCTAssertEqual(page.expenses.first?.amount, 200)
        XCTAssertEqual(page.expenses.first?.currency, "RUB")
    }
}

private extension ExpesiesListExpensesProviderTests {
    func makeExpense(id: String, description: String?) -> ExpenseDTO {
        ExpenseDTO(
            id: id,
            title: "Coffee",
            description: description,
            amount: 4.5,
            currency: "USD",
            category: "cat-1",
            timeOfAdd: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}

private actor ExpesiesListExpensesServiceSpy: MainExpensesContractServicing {
    private let listResult: Result<ExpensesListResponseDTO, Error>
    private var parametersHistory: [ExpensesListQueryParameters] = []

    init(listResult: Result<ExpensesListResponseDTO, Error>) {
        self.listResult = listResult
    }

    func createExpenses(_ request: ExpensesCreateRequestDTO) async throws -> ExpensesCreateResponseDTO {
        throw StubError.any
    }

    func listExpenses(parameters: ExpensesListQueryParameters) async throws -> ExpensesListResponseDTO {
        parametersHistory.append(parameters)
        return try listResult.get()
    }

    func deleteExpense(id: String) async throws {
        throw StubError.any
    }

    func requestedParameters() -> [ExpensesListQueryParameters] {
        parametersHistory
    }
}

private enum StubError: Error {
    case any
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
