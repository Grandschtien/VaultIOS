// Created by Egor Shkarin on 28.03.2026

import Foundation

struct CategoryFetchData: Sendable {
    let navigationTitle: String
    let fromDate: Date
    let toDate: Date
    let loadingState: LoadingStatus
    let hasResolvedCurrentPeriodContent: Bool
    let category: MainCategoryCardModel?
    let expenseGroups: [MainExpenseGroupModel]
    let deletingExpenseIDs: Set<String>
    let canEditCategory: Bool
    let isLoadingNextPage: Bool
    let hasMore: Bool

    init(
        navigationTitle: String = "",
        fromDate: Date = Date(),
        toDate: Date = Date(),
        loadingState: LoadingStatus = .idle,
        hasResolvedCurrentPeriodContent: Bool = false,
        category: MainCategoryCardModel? = nil,
        expenseGroups: [MainExpenseGroupModel] = [],
        deletingExpenseIDs: Set<String> = [],
        canEditCategory: Bool = false,
        isLoadingNextPage: Bool = false,
        hasMore: Bool = false
    ) {
        self.navigationTitle = navigationTitle
        self.fromDate = fromDate
        self.toDate = toDate
        self.loadingState = loadingState
        self.hasResolvedCurrentPeriodContent = hasResolvedCurrentPeriodContent
        self.category = category
        self.expenseGroups = expenseGroups
        self.deletingExpenseIDs = deletingExpenseIDs
        self.canEditCategory = canEditCategory
        self.isLoadingNextPage = isLoadingNextPage
        self.hasMore = hasMore
    }
}
