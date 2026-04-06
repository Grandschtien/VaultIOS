// Created by Egor Shkarin on 27.03.2026

import Foundation
import UIKit
internal import Combine

@MainActor
protocol CategoriesListPresentationLogic: Sendable {
    func presentFetchedData(_ data: CategoriesListFetchData)
}

final class CategoriesListPresenter: CategoriesListPresentationLogic {
    private enum Constants {
        static let loadingItemsCount = 10
    }

    @Published
    private(set) var viewModel: CategoriesListViewModel

    weak var handler: CategoriesListHandler?

    private let formatter: MainValueFormatting
    private let colorProvider: CategoryColorProviding

    init(
        viewModel: CategoriesListViewModel,
        formatter: MainValueFormatting,
        colorProvider: CategoryColorProviding
    ) {
        self.viewModel = viewModel
        self.formatter = formatter
        self.colorProvider = colorProvider
    }

    func presentFetchedData(_ data: CategoriesListFetchData) {
        let items = makeItems(from: data)

        viewModel = CategoriesListViewModel(
            navigationTitle: .init(
                text: data.navigationTitle,
                font: Typography.typographyBold20,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .left
            ),
            addButton: .init(
                content: .plus,
                tintColor: Asset.Colors.interactiveElemetsPrimary.color,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapAddCategory()
                }
            ),
            state: makeState(
                from: data,
                items: items
            )
        )
    }
}

private extension CategoriesListPresenter {
    func makeState(
        from data: CategoriesListFetchData,
        items: [CategoryCollectionViewCell.ViewModel]
    ) -> CategoriesListViewModel.State {
        switch data.loadingState {
        case .idle, .loading:
            return .loading(items: items)
        case .failed:
            return .error(makeErrorViewModel())
        case .loaded:
            guard !items.isEmpty else {
                return .empty(text: L10n.mainOverviewEmptyCategories)
            }

            return .loaded(items: items)
        }
    }

    func makeItems(from data: CategoriesListFetchData) -> [CategoryCollectionViewCell.ViewModel] {
        switch data.loadingState {
        case .idle, .loading:
            return (0..<Constants.loadingItemsCount).map { _ in
                CategoryCollectionViewCell.ViewModel(isLoading: true)
            }
        case .failed:
            return []
        case .loaded:
            return data.categories.map { category in
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
}
