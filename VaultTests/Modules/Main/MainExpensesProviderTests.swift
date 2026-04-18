import XCTest
@testable import Vault

final class MainExpensesProviderTests: XCTestCase {
    func testFetchExpensesRequestsFiveItemsAndCapsOutputToFive() async throws {
        let expensesService = ExpensesServiceSpy(
            listResult: .success(
                .init(
                    expenses: makeExpenses(count: 7),
                    nextCursor: "cursor-1",
                    hasMore: true
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

        let sut = MainExpensesProvider(
            expensesService: expensesService,
            currencyConversionService: UserCurrencyConversionService(
                userProfileStorageService: profileStorage
            )
        )

        let expenses = try await sut.fetchExpenses()
        let requestedParameters = await expensesService.requestedParameters()

        XCTAssertEqual(requestedParameters, [.init(limit: 5)])
        XCTAssertEqual(expenses.count, 5)
        XCTAssertEqual(expenses.map(\.id), ["expense-1", "expense-2", "expense-3", "expense-4", "expense-5"])
        XCTAssertEqual(expenses.first?.amount, 0.5)
        XCTAssertEqual(expenses.first?.currency, "EUR")
    }
}

extension MainExpensesProviderTests {
    func testFetchExpensesMapsNilDescriptionToEmptyString() async throws {
        let expense = ExpenseDTO(
            id: "expense-1",
            title: "Taxi",
            description: nil,
            amount: 24,
            currency: "USD",
            category: "transport",
            timeOfAdd: .init(timeIntervalSince1970: 1_700_000_000)
        )

        let expensesService = ExpensesServiceSpy(
            listResult: .success(
                .init(
                    expenses: [expense],
                    nextCursor: nil,
                    hasMore: false
                )
            )
        )

        let sut = MainExpensesProvider(
            expensesService: expensesService,
            currencyConversionService: UserCurrencyConversionService(
                userProfileStorageService: UserProfileStorageSpy(profile: nil)
            )
        )

        let expenses = try await sut.fetchExpenses()
        XCTAssertEqual(expenses.first?.description, "")
    }

    func testFetchExpensesShowsOriginalAmountWhenOriginalCurrencyMatchesPreferredCurrency() async throws {
        let expense = ExpenseDTO(
            id: "expense-1",
            title: "Coffee",
            description: "Morning",
            amount: 2.62,
            currency: "USD",
            originalAmount: 200,
            originalCurrency: "RUB",
            category: "transport",
            timeOfAdd: .init(timeIntervalSince1970: 1_700_000_000)
        )

        let expensesService = ExpensesServiceSpy(
            listResult: .success(
                .init(
                    expenses: [expense],
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

        let sut = MainExpensesProvider(
            expensesService: expensesService,
            currencyConversionService: UserCurrencyConversionService(
                userProfileStorageService: profileStorage
            )
        )

        let expenses = try await sut.fetchExpenses()

        XCTAssertEqual(expenses.first?.amount, 200)
        XCTAssertEqual(expenses.first?.currency, "RUB")
    }
}

private extension MainExpensesProviderTests {
    func makeExpenses(count: Int) -> [ExpenseDTO] {
        (1...count).map { index in
            ExpenseDTO(
                id: "expense-\(index)",
                title: "Expense \(index)",
                description: "Description \(index)",
                amount: Double(index),
                currency: "USD",
                category: "category-\(index)",
                timeOfAdd: .init(timeIntervalSince1970: TimeInterval(1_700_000_000 + index))
            )
        }
    }
}

private actor ExpensesServiceSpy: MainExpensesContractServicing {
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
