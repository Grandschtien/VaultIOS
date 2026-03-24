//
//  MainExpensesProvider.swift
//  Vault
//
//  Created by Егор Шкарин on 24.03.2026.
//

import Foundation

protocol MainExpensesProviding: Sendable {
    func fetchExpenses() async throws -> [MainExpenseModel]
}

final class MainExpensesProvider: MainExpensesProviding {
    private enum Constants {
        static let visibleExpensesLimit = 5
    }

    private let expensesService: MainExpensesContractServicing

    init(expensesService: MainExpensesContractServicing) {
        self.expensesService = expensesService
    }

    func fetchExpenses() async throws -> [MainExpenseModel] {
        let response = try await expensesService.listExpenses(
            parameters: .init(limit: Constants.visibleExpensesLimit)
        )

        return response.expenses.prefix(Constants.visibleExpensesLimit).map { expense in
            MainExpenseModel(
                id: expense.id,
                title: expense.title,
                description: expense.description ?? "",
                amount: expense.amount,
                currency: expense.currency,
                category: expense.category,
                timeOfAdd: expense.timeOfAdd
            )
        }
    }
}
