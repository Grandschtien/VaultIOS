// Created by Egor Shkarin on 28.03.2026

import Foundation

struct CategoryExpensesPage: Equatable, Sendable {
    let expenses: [MainExpenseModel]
    let nextCursor: String?
    let hasMore: Bool
}

protocol CategorySummaryProviding: Sendable {
    func fetchCategory(id: String) async throws -> MainCategoryCardModel
}

protocol CategoryExpensesProviding: Sendable {
    func fetchExpensesPage(
        categoryID: String,
        cursor: String?,
        limit: Int
    ) async throws -> CategoryExpensesPage
    func deleteExpense(id: String) async throws
}

final class CategorySummaryProvider: CategorySummaryProviding {
    private enum Constants {
        static let unmappedBackendName = "Unmapped"
    }

    private let categoriesService: MainCategoriesContractServicing
    private let currencyConversionService: UserCurrencyConverting

    init(
        categoriesService: MainCategoriesContractServicing,
        currencyConversionService: UserCurrencyConverting
    ) {
        self.categoriesService = categoriesService
        self.currencyConversionService = currencyConversionService
    }

    func fetchCategory(id: String) async throws -> MainCategoryCardModel {
        let category = try await categoriesService.getCategory(id: id).category
        let convertedAmount = currencyConversionService.convertUsdAmount(category.totalSpentUsd ?? .zero)

        return MainCategoryCardModel(
            id: category.id,
            name: localizedCategoryName(from: category.name),
            icon: category.icon,
            color: category.color,
            amount: convertedAmount.amount,
            currency: convertedAmount.currency
        )
    }
}

private extension CategorySummaryProvider {
    func localizedCategoryName(from backendName: String) -> String {
        if backendName.compare(Constants.unmappedBackendName, options: [.caseInsensitive]) == .orderedSame {
            return L10n.other
        }

        return backendName
    }
}

final class CategoryExpensesProvider: CategoryExpensesProviding {
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
        categoryID: String,
        cursor: String?,
        limit: Int
    ) async throws -> CategoryExpensesPage {
        let response = try await expensesService.listExpenses(
            parameters: .init(
                category: categoryID,
                cursor: cursor,
                limit: limit
            )
        )

        return CategoryExpensesPage(
            expenses: response.expenses.map { expense in
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
            },
            nextCursor: response.nextCursor,
            hasMore: response.hasMore
        )
    }

    func deleteExpense(id: String) async throws {
        try await expensesService.deleteExpense(id: id)
    }
}
