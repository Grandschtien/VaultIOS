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

        let sut = MainExpensesProvider(expensesService: expensesService)

        let expenses = try await sut.fetchExpenses()
        let requestedParameters = await expensesService.requestedParameters()

        XCTAssertEqual(requestedParameters, [.init(limit: 5)])
        XCTAssertEqual(expenses.count, 5)
        XCTAssertEqual(expenses.map(\.id), ["expense-1", "expense-2", "expense-3", "expense-4", "expense-5"])
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

        let sut = MainExpensesProvider(expensesService: expensesService)

        let expenses = try await sut.fetchExpenses()
        XCTAssertEqual(expenses.first?.description, "")
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
