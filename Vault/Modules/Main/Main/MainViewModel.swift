// Created by Egor Shkarin 23.03.2026

import Foundation

struct MainViewModel: Equatable {
    let navigationTitle: Label.LabelViewModel
    let summarySection: MainSummarySectionView.ViewModel
    let categoriesSection: MainCategoriesSectionView.ViewModel
    let expensesSection: MainExpensesSectionView.ViewModel

    init(
        navigationTitle: Label.LabelViewModel = .init(),
        summarySection: MainSummarySectionView.ViewModel = .init(),
        categoriesSection: MainCategoriesSectionView.ViewModel = .init(),
        expensesSection: MainExpensesSectionView.ViewModel = .init()
    ) {
        self.navigationTitle = navigationTitle
        self.summarySection = summarySection
        self.categoriesSection = categoriesSection
        self.expensesSection = expensesSection
    }
}
