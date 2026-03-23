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

    init(
        viewModel: MainViewModel,
        formatter: MainValueFormatting
    ) {
        self.viewModel = viewModel
        self.formatter = formatter
    }

    func presentFetchedData(_ data: MainFetchData) {
        let categoryMap = Dictionary(uniqueKeysWithValues: data.categories.map { ($0.id, $0) })

        viewModel = MainViewModel(
            navigationTitle: .init(
                text: data.navigationTitle,
                font: Typography.typographyBold24,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .left
            ),
            summarySection: makeSummarySectionViewModel(from: data),
            categoriesSection: makeCategoriesSectionViewModel(from: data),
            expensesSection: makeExpensesSectionViewModel(from: data, categories: categoryMap)
        )
    }
}

private extension MainPresenter {
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
                isLoading: true
            )

        case let .failed(error):
            return .init(
                title: .init(
                    text: L10n.mainOverviewTotalSpending,
                    font: Typography.typographyMedium14,
                    textColor: Asset.Colors.textAndIconPrimaryInverted.color.withAlphaComponent(0.75),
                    alignment: .left
                ),
                amount: .init(
                    text: L10n.mainOverviewError,
                    font: Typography.typographyBold30,
                    textColor: Asset.Colors.textAndIconPrimaryInverted.color,
                    alignment: .left
                ),
                trend: .init(
                    text: error.localizedDescription,
                    font: Typography.typographyRegular12,
                    textColor: Asset.Colors.textAndIconPrimaryInverted.color.withAlphaComponent(0.9),
                    alignment: .left
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
                trend: .init(
                    text: formatter.formatSummaryChange(summary.changePercent),
                    font: Typography.typographyRegular12,
                    textColor: Asset.Colors.textAndIconPrimaryInverted.color,
                    alignment: .left
                )
            )
        }
    }

    func makeCategoriesSectionViewModel(from data: MainFetchData) -> MainCategoriesSectionView.ViewModel {
        let categories: [CategoryCollectionViewCell.ViewModel]
        if data.categoriesState.isLoading {
            categories = (0..<4).map { _ in
                CategoryCollectionViewCell.ViewModel(isLoading: true)
            }
        } else {
            categories = data.categories.map { category in
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
                    iconBackgroundColor: color(for: category.color),
                    tapCommand: .nope
                )
            }
        }

        let emptyMessage: String?
        switch data.categoriesState {
        case .idle, .loading:
            emptyMessage = nil
        case .loaded:
            emptyMessage = categories.isEmpty ? L10n.mainOverviewEmptyCategories : nil
        case let .failed(error):
            emptyMessage = error.localizedDescription
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
            items: categories
        )
    }

    func makeExpensesSectionViewModel(
        from data: MainFetchData,
        categories: [String: MainCategoryCardModel]
    ) -> MainExpensesSectionView.ViewModel {
        let sections: [MainExpensesSectionView.SectionViewModel]
        if data.expensesState.isLoading {
            sections = [
                .init(
                    title: .init(
                        text: "",
                        font: Typography.typographyBold12,
                        textColor: Asset.Colors.textAndIconPlaceseholder.color,
                        alignment: .left
                    ),
                    items: (0..<2).map { _ in ExpenseCollectionViewCell.ViewModel(isLoading: true) }
                )
            ]
        } else {
            sections = data.expenseGroups.map { group in
                let rows: [ExpenseCollectionViewCell.ViewModel] = group.expenses.map { expense in
                    let category = categories[expense.category]
                    let amountText = "-\(formatter.formatAmount(expense.amount, currencyCode: expense.currency))"

                    return ExpenseCollectionViewCell.ViewModel(
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
                        iconBackgroundColor: color(for: category?.color ?? ""),
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
        }

        let emptyMessage: String?
        switch data.expensesState {
        case .idle, .loading:
            emptyMessage = nil
        case .loaded:
            emptyMessage = sections.isEmpty ? L10n.mainOverviewEmptyExpenses : nil
        case let .failed(error):
            emptyMessage = error.localizedDescription
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
            isLoading: data.expensesState.isLoading,
            emptyText: emptyMessage,
            sections: sections
        )
    }

    func color(for value: String) -> UIColor {
        switch value {
        case "light_red", "light_orange":
            return UIColor(red: 1.0, green: 0.93, blue: 0.84, alpha: 1)
        case "light_blue":
            return UIColor(red: 0.86, green: 0.92, blue: 0.99, alpha: 1)
        case "light_purple":
            return UIColor(red: 0.91, green: 0.84, blue: 1.0, alpha: 1)
        case "light_pink":
            return UIColor(red: 0.99, green: 0.91, blue: 0.95, alpha: 1)
        default:
            return Asset.Colors.interactiveInputBackground.color
        }
    }
}

private extension LoadingStatus {
    var isLoading: Bool {
        if case .loading = self {
            return true
        }

        return false
    }
}
