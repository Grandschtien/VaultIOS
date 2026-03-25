// Created by Egor Shkarin 23.03.2026

import Foundation

struct MainFetchData: Sendable {
    let navigationTitle: String
    let blockingErrorDescription: String?
    let summaryState: LoadingStatus
    let categoriesState: LoadingStatus
    let expensesState: LoadingStatus
    let summary: MainSummaryModel?
    let categories: [MainCategoryCardModel]
    let expenseGroups: [MainExpenseGroupModel]

    init(
        navigationTitle: String = L10n.mainOverviewTitle,
        blockingErrorDescription: String? = nil,
        summaryState: LoadingStatus = .idle,
        categoriesState: LoadingStatus = .idle,
        expensesState: LoadingStatus = .idle,
        summary: MainSummaryModel? = nil,
        categories: [MainCategoryCardModel] = [],
        expenseGroups: [MainExpenseGroupModel] = []
    ) {
        self.navigationTitle = navigationTitle
        self.blockingErrorDescription = blockingErrorDescription
        self.summaryState = summaryState
        self.categoriesState = categoriesState
        self.expensesState = expensesState
        self.summary = summary
        self.categories = categories
        self.expenseGroups = expenseGroups
    }
}
