// Created by Egor Shkarin on 25.03.2026

import Foundation

struct ExpesiesListExpensesPage: Equatable, Sendable {
    let expenses: [MainExpenseModel]
    let nextCursor: String?
    let hasMore: Bool
}

protocol ExpesiesListExpensesProviding: Sendable {
    func fetchExpensesPage(
        cursor: String?,
        limit: Int
    ) async throws -> ExpesiesListExpensesPage
}

protocol ExpesiesListCategoriesProviding: Sendable {
    func fetchCategories() async throws -> [MainCategoryModel]
}

final class ExpesiesListExpensesProvider: ExpesiesListExpensesProviding {
    private let expensesService: MainExpensesContractServicing
    private let currencyConversionService: UserCurrencyConverting

    init(
        expensesService: MainExpensesContractServicing,
        currencyConversionService: UserCurrencyConverting
    ) {
        self.expensesService = expensesService
        self.currencyConversionService = currencyConversionService
    }

    func fetchExpensesPage(
        cursor: String?,
        limit: Int
    ) async throws -> ExpesiesListExpensesPage {
        let response = try await expensesService.listExpenses(
            parameters: .init(
                cursor: cursor,
                limit: limit
            )
        )

        return ExpesiesListExpensesPage(
            expenses: response.expenses.map { expense in
                let convertedAmount = currencyConversionService.convertExpense(
                    amount: expense.amount,
                    currency: expense.currency
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
            },
            nextCursor: response.nextCursor,
            hasMore: response.hasMore
        )
    }
}

actor ExpesiesListCategoriesProvider: ExpesiesListCategoriesProviding {
    private let categoriesService: MainCategoriesContractServicing

    init(categoriesService: MainCategoriesContractServicing) {
        self.categoriesService = categoriesService
    }

    func fetchCategories() async throws -> [MainCategoryModel] {
        let response = try await categoriesService.listCategories()
        return response.categories.map { category in
            MainCategoryModel(
                id: category.id,
                name: category.name,
                icon: category.icon,
                color: category.color
            )
        }
    }
}
