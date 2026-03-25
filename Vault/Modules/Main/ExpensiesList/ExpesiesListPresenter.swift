// Created by Egor Shkarin 25.03.2026

import Foundation
import UIKit
internal import Combine

@MainActor
protocol ExpesiesListPresentationLogic: Sendable {
    func presentFetchedData(_ data: ExpesiesListFetchData)
}

final class ExpesiesListPresenter: ExpesiesListPresentationLogic {

    @Published
    private(set) var viewModel: ExpesiesListViewModel

    weak var handler: ExpesiesListHandler?
    private let formatter: MainValueFormatting

    init(
        viewModel: ExpesiesListViewModel,
        formatter: MainValueFormatting
    ) {
        self.viewModel = viewModel
        self.formatter = formatter
    }

    func presentFetchedData(_ data: ExpesiesListFetchData) {
        let categoriesByID = Dictionary(uniqueKeysWithValues: data.categories.map { ($0.id, $0) })
        let sections = makeSections(from: data, categoriesByID: categoriesByID)

        viewModel = ExpesiesListViewModel(
            navigationTitle: .init(
                text: data.navigationTitle,
                font: Typography.typographyBold20,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .left
            ),
            state: makeState(
                from: data,
                sections: sections
            ),
            loadNextPageCommand: Command { [weak handler] in
                await handler?.handleLoadNextPage()
            }
        )
    }
}

private extension ExpesiesListPresenter {
    func makeState(
        from data: ExpesiesListFetchData,
        sections: [ExpesiesListViewModel.SectionViewModel]
    ) -> ExpesiesListViewModel.State {
        switch data.loadingState {
        case .idle, .loading:
            return .loading(sections: sections)
        case .failed:
            return .error(makeErrorViewModel())
        case .loaded:
            guard !sections.isEmpty else {
                return .empty(text: L10n.mainOverviewEmptyExpenses)
            }

            return .loaded(
                .init(
                    sections: sections,
                    isLoadingNextPage: data.isLoadingNextPage,
                    hasMore: data.hasMore
                )
            )
        }
    }

    func makeSections(
        from data: ExpesiesListFetchData,
        categoriesByID: [String: MainCategoryModel]
    ) -> [ExpesiesListViewModel.SectionViewModel] {
        switch data.loadingState {
        case .idle, .loading:
            return [
                .init(
                    title: .init(
                        text: "",
                        font: Typography.typographyBold12,
                        textColor: Asset.Colors.textAndIconPlaceseholder.color,
                        alignment: .left
                    ),
                    items: (0..<6).map { _ in
                        ExpenseCollectionViewCell.ViewModel(isLoading: true)
                    }
                )
            ]
        case .failed:
            return []
        case .loaded:
            return data.expenseGroups.map { group in
                let items: [ExpenseCollectionViewCell.ViewModel] = group.expenses.map { expense in
                    let category = categoriesByID[expense.category]
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

                return .init(
                    title: .init(
                        text: formatter.formatSectionDate(group.date, now: Date()),
                        font: Typography.typographyBold12,
                        textColor: Asset.Colors.textAndIconPlaceseholder.color,
                        alignment: .left
                    ),
                    items: items
                )
            }
        }
    }

    func makeErrorViewModel() -> FullScreenCommonErrorView.ViewModel {
        FullScreenCommonErrorView.ViewModel(
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
