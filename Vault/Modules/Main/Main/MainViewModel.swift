// Created by Egor Shkarin 23.03.2026

import Foundation

struct MainViewModel: Equatable {
    let navigationTitle: Label.LabelViewModel
    let periodButton: MainPeriodBarButtonView.ViewModel
    let pullToRefreshCommand: Command
    let blockingErrorViewModel: MainBlockingErrorView.ViewModel?
    let isRefreshing: Bool
    let isInteractionBlocked: Bool
    let summarySection: MainSummarySectionView.ViewModel
    let categoriesSection: MainCategoriesSectionView.ViewModel
    let expensesSection: MainExpensesSectionView.ViewModel

    init(
        navigationTitle: Label.LabelViewModel = .init(),
        periodButton: MainPeriodBarButtonView.ViewModel = .init(),
        pullToRefreshCommand: Command = .nope,
        blockingErrorViewModel: MainBlockingErrorView.ViewModel? = nil,
        isRefreshing: Bool = false,
        isInteractionBlocked: Bool = false,
        summarySection: MainSummarySectionView.ViewModel = .init(),
        categoriesSection: MainCategoriesSectionView.ViewModel = .init(),
        expensesSection: MainExpensesSectionView.ViewModel = .init()
    ) {
        self.navigationTitle = navigationTitle
        self.periodButton = periodButton
        self.pullToRefreshCommand = pullToRefreshCommand
        self.blockingErrorViewModel = blockingErrorViewModel
        self.isRefreshing = isRefreshing
        self.isInteractionBlocked = isInteractionBlocked
        self.summarySection = summarySection
        self.categoriesSection = categoriesSection
        self.expensesSection = expensesSection
    }
}
