// Created by Egor Shkarin 23.03.2026

import Foundation
import UIKit
internal import Combine

@MainActor
protocol MainPresentationLogic: Sendable {
    func presentFetchedData(_ data: MainFetchData)
}

final class MainPresenter: MainPresentationLogic {
    @Published
    private(set) var viewModel: MainViewModel

    weak var handler: MainHandler?

    private let formatter: MainValueFormatting
    private let colorProvider: CategoryColorProviding

    init(
        viewModel: MainViewModel,
        formatter: MainValueFormatting,
        colorProvider: CategoryColorProviding
    ) {
        self.viewModel = viewModel
        self.formatter = formatter
        self.colorProvider = colorProvider

        presentFetchedData(
            MainFetchData(
                summaryState: .loading,
                categoriesState: .loading,
                expensesState: .loading
            )
        )
    }

    func presentFetchedData(_ data: MainFetchData) {
        let categoryMap = Dictionary(uniqueKeysWithValues: data.categories.map { ($0.id, $0) })
        let blockingErrorViewModel = makeBlockingErrorViewModel(from: data)

        viewModel = MainViewModel(
            navigationTitle: .init(
                text: data.navigationTitle,
                font: Typography.typographyBold24,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .left
            ),
            blockingErrorViewModel: blockingErrorViewModel,
            isInteractionBlocked: blockingErrorViewModel != nil,
            summarySection: makeSummarySectionViewModel(from: data),
            categoriesSection: makeCategoriesSectionViewModel(from: data),
            expensesSection: makeExpensesSectionViewModel(from: data, categories: categoryMap)
        )
    }
}

private extension MainPresenter {
    func makeBlockingErrorViewModel(from data: MainFetchData) -> MainBlockingErrorView.ViewModel? {
        guard let description = data.blockingErrorDescription else {
            return nil
        }

        return .init(
            title: .init(
                text: L10n.mainOverviewError,
                font: Typography.typographyBold24,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .center,
                numberOfLines: 0
            ),
            subtitle: .init(
                text: description,
                font: Typography.typographyRegular16,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .center,
                numberOfLines: 0
            ),
            retryButton: .init(
                title: "Retry",
                titleColor: Asset.Colors.textAndIconPrimaryInverted.color,
                backgroundColor: Asset.Colors.interactiveElemetsPrimary.color,
                font: Typography.typographySemibold16,
                isEnabled: true,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapRetryBlockingError()
                }
            )
        )
    }

    func makeSummarySectionViewModel(from data: MainFetchData) -> MainSummarySectionView.ViewModel {
        switch data.summaryState {
        case .loading:
            return .init(
                title: .init(
                    text: L10n.mainOverviewTotalSpending,
                    font: Typography.typographyMedium14,
                    textColor: Asset.Colors.textAndIconPrimaryInverted.color.withAlphaComponent(0.75),
                    alignment: .left
                ),
                amount: .init(
                    text: L10n.mainOverviewLoading,
                    font: Typography.typographyBold30,
                    textColor: Asset.Colors.textAndIconPrimaryInverted.color,
                    alignment: .left
                ),
                trend: .init(
                    text: "",
                    font: Typography.typographyRegular12,
                    textColor: Asset.Colors.textAndIconPrimaryInverted.color,
                    alignment: .left
                ),
                isLoading: data.summaryState == .loading
            )

        case .failed:
            return .init(
                errorViewModel: makeSectionErrorViewModel(
                    command: Command { [weak handler] in
                        await handler?.handleTapRetrySummary()
                    }
                )
            )

        case .idle, .loaded:
            guard let summary = data.summary else {
                return .init(
                    title: .init(
                        text: L10n.mainOverviewTotalSpending,
                        font: Typography.typographyMedium14,
                        textColor: Asset.Colors.textAndIconPrimaryInverted.color.withAlphaComponent(0.75),
                        alignment: .left
                    ),
                    amount: .init(
                        text: L10n.mainOverviewLoading,
                        font: Typography.typographyBold30,
                        textColor: Asset.Colors.textAndIconPrimaryInverted.color,
                        alignment: .left
                    ),
                    trend: .init(
                        text: "",
                        font: Typography.typographyRegular12,
                        textColor: Asset.Colors.textAndIconPrimaryInverted.color,
                        alignment: .left
                    )
                )
            }

            return .init(
                title: .init(
                    text: L10n.mainOverviewTotalSpending,
                    font: Typography.typographyMedium14,
                    textColor: Asset.Colors.textAndIconPrimaryInverted.color.withAlphaComponent(0.75),
                    alignment: .left
                ),
                amount: .init(
                    text: formatter.formatAmount(summary.totalAmount, currencyCode: summary.currency),
                    font: Typography.typographyBold30,
                    textColor: Asset.Colors.textAndIconPrimaryInverted.color,
                    alignment: .left
                ),
                // TODO: Support on backend side
                trend: nil
            )
        }
    }

    func makeCategoriesSectionViewModel(from data: MainFetchData) -> MainCategoriesSectionView.ViewModel {
        let categories: [CategoryCollectionViewCell.ViewModel]
        
        switch data.categoriesState {
        case .loaded:
            categories = data.categories.prefix(4).map { category in
                CategoryCollectionViewCell.ViewModel(
                    id: category.id,
                    iconText: category.icon,
                    title: .init(
                        text: category.name,
                        font: Typography.typographyMedium16,
                        textColor: Asset.Colors.textAndIconSecondary.color,
                        alignment: .left
                    ),
                    amount: .init(
                        text: formatter.formatAmount(category.amount, currencyCode: category.currency),
                        font: Typography.typographyBold18,
                        textColor: Asset.Colors.textAndIconPrimary.color,
                        alignment: .left
                    ),
                    isAmountHidden: false,
                    iconBackgroundColor: colorProvider.summaryColor(for: category.color),
                    tapCommand: Command { [weak handler] in
                        await handler?.handleTapCategory(
                            id: category.id,
                            name: category.name
                        )
                    }
                )
            }
        case .loading:
            categories = (0..<4).map { _ in
                CategoryCollectionViewCell.ViewModel(isLoading: true)
            }
        case .failed, .idle:
            categories = []
        }

        let emptyMessage: String?
        switch data.categoriesState {
        case .idle, .loading:
            emptyMessage = nil
        case .loaded:
            emptyMessage = categories.isEmpty ? L10n.mainOverviewEmptyCategories : nil
        case .failed:
            emptyMessage = nil
        }

        return .init(
            title: .init(
                text: L10n.mainOverviewCategories,
                font: Typography.typographyBold14,
                textColor: Asset.Colors.textAndIconPlaceseholder.color,
                alignment: .left
            ),
            seeAllTitle: .init(
                text: L10n.mainOverviewSeeAll,
                font: Typography.typographyBold12,
                textColor: Asset.Colors.interactiveElemetsPrimary.color,
                alignment: .right
            ),
            seeAllCommand: Command { [weak handler] in
                await handler?.handleTapSeeAllCategories()
            },
            isLoading: data.categoriesState.isLoading,
            emptyText: emptyMessage,
            errorViewModel: data.categoriesState.isFailed
                ? makeSectionErrorViewModel(
                    command: Command { [weak handler] in
                        await handler?.handleTapRetryCategories()
                    }
                )
                : nil,
            items: categories
        )
    }

    func makeExpensesSectionViewModel(
        from data: MainFetchData,
        categories: [String: MainCategoryCardModel]
    ) -> MainExpensesSectionView.ViewModel {
        let state: MainExpensesSectionView.State
        
        switch data.expensesState {
        case .loading, .idle:
            state = .loading
        case .failed:
            state = .error(
                makeSectionErrorViewModel(
                    command: Command { [weak handler] in
                        await handler?.handleTapRetryExpenses()
                    }
                )
            )
        case .loaded:
            let sections = data.expenseGroups.prefix(6).map { group in
                let rows: [ExpenseView.ViewModel] = group.expenses.map { expense in
                    let category = categories[expense.category]
                    let amountText = formatter.formatExpenseAmount(
                        expense.amount,
                        currencyCode: expense.currency
                    )

                    return ExpenseView.ViewModel(
                        id: expense.id,
                        iconText: category?.icon ?? "💸",
                        title: .init(
                            text: expense.title,
                            font: Typography.typographyBold14,
                            textColor: Asset.Colors.textAndIconPrimary.color,
                            alignment: .left
                        ),
                        subtitle: .init(
                            text: formatter.formatExpenseTime(expense.timeOfAdd, now: Date()),
                            font: Typography.typographyRegular12,
                            textColor: Asset.Colors.textAndIconPlaceseholder.color,
                            alignment: .left
                        ),
                        amount: .init(
                            text: amountText,
                            font: Typography.typographyBold14,
                            textColor: .systemRed,
                            alignment: .right
                        ),
                        iconBackgroundColor: colorProvider.summaryColor(for: category?.color ?? ""),
                        tapCommand: .nope
                    )
                }

                return MainExpensesSectionView.SectionViewModel(
                    title: .init(
                        text: formatter.formatSectionDate(group.date, now: Date()),
                        font: Typography.typographyBold12,
                        textColor: Asset.Colors.textAndIconPlaceseholder.color,
                        alignment: .left
                    ),
                    items: rows
                )
            }

            if sections.isEmpty {
                state = .empty(text: L10n.mainOverviewEmptyExpenses)
            } else {
                state = .loaded(content: sections)
            }
        }

        return .init(
            title: .init(
                text: L10n.mainOverviewRecentExpenses,
                font: Typography.typographyBold14,
                textColor: Asset.Colors.textAndIconPlaceseholder.color,
                alignment: .left
            ),
            seeAllTitle: .init(
                text: L10n.mainOverviewSeeAll,
                font: Typography.typographyBold12,
                textColor: Asset.Colors.interactiveElemetsPrimary.color,
                alignment: .right
            ),
            seeAllCommand: Command { [weak handler] in
                await handler?.handleTapSeeAllExpenses()
            },
            state: state
        )
    }

    func makeSectionErrorViewModel(command: Command) -> FullScreenCommonErrorView.ViewModel {
        .init(
            title: .init(
                text: "Failed to load",
                font: Typography.typographyBold14,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .center
            ),
            tapCommand: command
        )
    }

}

private extension LoadingStatus {
    var isLoading: Bool {
        if case .loading = self {
            return true
        }

        return false
    }

    var isFailed: Bool {
        if case .failed = self {
            return true
        }

        return false
    }
}
