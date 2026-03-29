// Created by Egor Shkarin on 28.03.2026

import Foundation
import UIKit
internal import Combine

@MainActor
protocol CategoryPresentationLogic: Sendable {
    func presentFetchedData(_ data: CategoryFetchData)
}

final class CategoryPresenter: CategoryPresentationLogic {
    private enum Constants {
        static let loadingRowsCount = 8
    }

    @Published
    private(set) var viewModel: CategoryViewModel

    weak var handler: CategoryHandler?
    private let formatter: MainValueFormatting
    private let colorProvider: CategoryColorProviding

    init(
        viewModel: CategoryViewModel,
        formatter: MainValueFormatting,
        colorProvider: CategoryColorProviding
    ) {
        self.viewModel = viewModel
        self.formatter = formatter
        self.colorProvider = colorProvider
    }

    func presentFetchedData(_ data: CategoryFetchData) {
        viewModel = CategoryViewModel(
            navigationTitle: .init(
                text: data.navigationTitle,
                font: Typography.typographyBold20,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .left
            ),
            editButtonTitle: L10n.categoryEditButton,
            editButtonCommand: Command { [weak handler] in
                await handler?.handleTapEditButton()
            },
            content: makeContent(from: data),
            loadNextPageCommand: Command { [weak handler] in
                await handler?.handleLoadNextPage()
            }
        )
    }
}

private extension CategoryPresenter {
    func makeContent(from data: CategoryFetchData) -> CategoryViewModel.ContentViewModel {
        let sections = makeSections(from: data)
        let state = makeContentState(from: data, sections: sections)

        return .init(
            summary: makeSummaryViewModel(from: data),
            state: state,
            isLoadingNextPage: data.isLoadingNextPage,
            hasMore: data.hasMore
        )
    }

    func makeContentState(
        from data: CategoryFetchData,
        sections: [CategoryViewModel.SectionViewModel]
    ) -> CategoryViewModel.ContentViewModel.State {
        switch data.loadingState {
        case .failed:
            return .failed(makeErrorViewModel())
        case .idle, .loading:
            return .loading(sections)
        case .loaded:
            return sections.isEmpty
                ? .empty(L10n.mainOverviewEmptyExpenses)
                : .loaded(sections)
        }
    }

    func makeSummaryViewModel(from data: CategoryFetchData) -> CategoryViewModel.SummaryViewModel {
        let category = data.category
        let isLoading: Bool
        let summaryColor = colorProvider.summaryColor(for: category?.color ?? "")

        switch data.loadingState {
        case .idle, .loading:
            isLoading = true
        case .failed, .loaded:
            isLoading = false
        }

        let amountText: String
        if let category {
            amountText = formatter.formatAmount(category.amount, currencyCode: category.currency)
        } else {
            amountText = L10n.mainOverviewLoading
        }

        return CategoryViewModel.SummaryViewModel(
            iconText: category?.icon ?? "💸",
            cardBackgroundColor: summaryColor,
            cardBorderColor: summaryColor.withAlphaComponent(0.8),
            iconBackgroundColor: colorProvider.accentColor(for: category?.color ?? ""),
            title: .init(
                text: L10n.categoryMonthlySpent,
                font: Typography.typographyMedium12,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .left
            ),
            amount: .init(
                text: amountText,
                font: Typography.typographyBold30,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .left
            ),
            note: .init(
                text: "",
                font: Typography.typographyMedium12,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .left
            ),
            isLoading: isLoading
        )
    }

    func makeSections(from data: CategoryFetchData) -> [CategoryViewModel.SectionViewModel] {
        switch data.loadingState {
        case .idle, .loading:
            return [
                .init(
                    id: "loading",
                    title: .init(
                        text: "",
                        font: Typography.typographyBold12,
                        textColor: Asset.Colors.textAndIconPlaceseholder.color,
                        alignment: .left
                    ),
                    items: (0..<Constants.loadingRowsCount).map { index in
                        .init(
                            id: "loading-\(index)",
                            isLoading: true
                        )
                    }
                )
            ]
        case .failed:
            return []
        case .loaded:
            let iconText = data.category?.icon ?? "💸"
            let iconBackground = colorProvider.summaryColor(for: data.category?.color ?? "")

            return data.expenseGroups.map { group in
                let items: [CategoryViewModel.ExpenseItemViewModel] = group.expenses.map { expense in
                    let amountText = formatter.formatExpenseAmount(
                        expense.amount,
                        currencyCode: expense.currency
                    )

                    return CategoryViewModel.ExpenseItemViewModel(
                        id: expense.id,
                        iconText: iconText,
                        iconBackgroundColor: iconBackground,
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
                        isLoading: false,
                        isDeleting: data.deletingExpenseIDs.contains(expense.id),
                        deleteCommand: Command { [weak handler] in
                            await handler?.handleDeleteExpense(id: expense.id)
                        }
                    )
                }

                return .init(
                    id: sectionIdentifier(from: group.date),
                    title: .init(
                        text: formatter.formatSectionDate(group.date, now: Date()),
                        font: Typography.typographyBold12,
                        textColor: Asset.Colors.textAndIconPlaceseholder.color,
                        alignment: .left,
                        numberOfLines: .zero,
                        lineBreakMode: .byWordWrapping
                    ),
                    items: items
                )
            }
        }
    }

    func makeErrorViewModel() -> FullScreenCommonErrorView.ViewModel {
        .init(
            title: .init(
                text: L10n.mainOverviewError,
                font: Typography.typographyBold14,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .center
            ),
            tapCommand: Command { [weak handler] in
                await handler?.handleTapRetry()
            }
        )
    }

    func sectionIdentifier(from date: Date) -> String {
        String(Int(date.timeIntervalSince1970))
    }
}
