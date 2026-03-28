// Created by Codex on 27.03.2026

import Foundation

struct CategoriesListFetchData: Sendable {
    let navigationTitle: String
    let loadingState: LoadingStatus
    let categories: [MainCategoryCardModel]

    init(
        navigationTitle: String = L10n.mainOverviewCategories,
        loadingState: LoadingStatus = .idle,
        categories: [MainCategoryCardModel] = []
    ) {
        self.navigationTitle = navigationTitle
        self.loadingState = loadingState
        self.categories = categories
    }
}
