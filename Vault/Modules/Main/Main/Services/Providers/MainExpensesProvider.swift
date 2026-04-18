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
    private let currencyConversionService: UserCurrencyConverting

    init(
        expensesService: MainExpensesContractServicing,
        currencyConversionService: UserCurrencyConverting
    ) {
        self.expensesService = expensesService
        self.currencyConversionService = currencyConversionService
    }

    func fetchExpenses() async throws -> [MainExpenseModel] {
        let response = try await expensesService.listExpenses(
            parameters: .init(limit: Constants.visibleExpensesLimit)
        )

        return response.expenses.prefix(Constants.visibleExpensesLimit).map { expense in
            let convertedAmount = currencyConversionService.convertExpense(
                amount: expense.amount,
                currency: expense.currency,
                originalAmount: expense.originalAmount,
                originalCurrency: expense.originalCurrency
            )
            return MainExpenseModel(
                id: expense.id,
                title: expense.title,
                description: expense.description ?? "",
                amount: convertedAmount.amount,
                currency: convertedAmount.currency,
                category: expense.category,
                timeOfAdd: expense.timeOfAdd
            )
        }
    }
}
