// Created by Egor Shkarin 25.03.2026

import Foundation

struct ExpesiesListFetchData: Sendable {
    let navigationTitle: String
    let loadingState: LoadingStatus
    let categories: [MainCategoryModel]
    let expenseGroups: [MainExpenseGroupModel]
    let isLoadingNextPage: Bool
    let hasMore: Bool

    init(
        navigationTitle: String = L10n.mainOverviewRecentExpenses,
        loadingState: LoadingStatus = .idle,
        categories: [MainCategoryModel] = [],
        expenseGroups: [MainExpenseGroupModel] = [],
        isLoadingNextPage: Bool = false,
        hasMore: Bool = true
    ) {
        self.navigationTitle = navigationTitle
        self.loadingState = loadingState
        self.categories = categories
        self.expenseGroups = expenseGroups
        self.isLoadingNextPage = isLoadingNextPage
        self.hasMore = hasMore
    }
}
