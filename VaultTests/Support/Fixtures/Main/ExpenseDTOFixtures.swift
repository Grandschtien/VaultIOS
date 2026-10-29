import Foundation
@testable import Vylok

enum ExpenseDTOFixtures {
    static let timeOfAdd = Date(timeIntervalSince1970: 1_700_000_000)

    static func makeExpense(
        id: String = "expense-1",
        title: String = "Coffee",
        description: String? = "Latte",
        amount: Double = 4.5,
        currency: String = "USD",
        originalAmount: Double? = nil,
        originalCurrency: String? = nil,
        category: String = "food",
        timeOfAdd: Date = timeOfAdd
    ) -> ExpenseDTO {
        ExpenseDTO(
            id: id,
            title: title,
            description: description,
            amount: amount,
            currency: currency,
            originalAmount: originalAmount,
            originalCurrency: originalCurrency,
            category: category,
            timeOfAdd: timeOfAdd
        )
    }

    static func makeExpenses(count: Int) -> [ExpenseDTO] {
        (1...count).map { makeExpense(id: "expense-\($0)", title: "Expense \($0)") }
    }

    static func makeListResponse(
        expenses: [ExpenseDTO] = [makeExpense()],
        nextCursor: String? = nil,
        hasMore: Bool = false
    ) -> ExpensesListResponseDTO {
        ExpensesListResponseDTO(expenses: expenses, nextCursor: nextCursor, hasMore: hasMore)
    }
}
