// Created by Egor Shkarin on 28.03.2026

import Foundation

struct CategoryFetchData: Sendable {
    let navigationTitle: String
    let fromDate: Date
    let loadingState: LoadingStatus
    let category: MainCategoryCardModel?
    let expenseGroups: [MainExpenseGroupModel]
    let deletingExpenseIDs: Set<String>
    let isLoadingNextPage: Bool
    let hasMore: Bool

    init(
        navigationTitle: String = "",
        fromDate: Date = Date(),
        loadingState: LoadingStatus = .idle,
        category: MainCategoryCardModel? = nil,
        expenseGroups: [MainExpenseGroupModel] = [],
        deletingExpenseIDs: Set<String> = [],
        isLoadingNextPage: Bool = false,
        hasMore: Bool = false
    ) {
        self.navigationTitle = navigationTitle
        self.fromDate = fromDate
        self.loadingState = loadingState
        self.category = category
        self.expenseGroups = expenseGroups
        self.deletingExpenseIDs = deletingExpenseIDs
        self.isLoadingNextPage = isLoadingNextPage
        self.hasMore = hasMore
    }
}
