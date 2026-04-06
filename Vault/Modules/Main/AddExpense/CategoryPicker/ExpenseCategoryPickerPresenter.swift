import UIKit
internal import Combine

@MainActor
protocol ExpenseCategoryPickerPresentationLogic: Sendable {
    func presentFetchedData(_ data: ExpenseCategoryPickerFetchData)
}

final class ExpenseCategoryPickerPresenter: ExpenseCategoryPickerPresentationLogic, ImageProviding {
    private enum Constants {
        static let loadingRowsCount = 6
    }

    @Published
    private(set) var viewModel: ExpenseCategoryPickerViewModel

    weak var handler: ExpenseCategoryPickerHandler?

    private let colorProvider: CategoryColorProviding

    init(
        viewModel: ExpenseCategoryPickerViewModel,
        colorProvider: CategoryColorProviding
    ) {
        self.viewModel = viewModel
        self.colorProvider = colorProvider
    }

    func presentFetchedData(_ data: ExpenseCategoryPickerFetchData) {
        let rows = makeRows(from: data)
        let isAddEnabled = data.selectedCategoryID != nil && data.loadingState == .loaded && !data.categories.isEmpty

        viewModel = ExpenseCategoryPickerViewModel(
            header: .init(
                title: .init(
                    text: data.title,
                    font: Typography.typographyBold20,
                    textColor: Asset.Colors.textAndIconPrimary.color,
                    alignment: .center
                ),
                closeCommand: Command { [weak handler] in
                    await handler?.handleTapClose()
                }
            ),
            state: makeState(from: data, rows: rows),
            addButton: .init(
                title: L10n.expenseCategoryPickerAdd,
                titleColor: Asset.Colors.textAndIconPrimaryInverted.color,
                backgroundColor: Asset.Colors.interactiveElemetsPrimary.color,
                font: Typography.typographySemibold16,
                isEnabled: isAddEnabled,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapAdd()
                },
                leftIcon: plusSystemImage
            )
        )
    }
}

private extension ExpenseCategoryPickerPresenter {
    func makeState(
        from data: ExpenseCategoryPickerFetchData,
        rows: [ExpenseCategoryPickerViewModel.RowViewModel]
    ) -> ExpenseCategoryPickerViewModel.State {
        switch data.loadingState {
        case .idle, .loading:
            return .loading(rows: rows)
        case .failed:
            return .error(
                .init(
                    title: .init(
                        text: L10n.expenseCategoryPickerError,
                        font: Typography.typographyBold14,
                        textColor: Asset.Colors.textAndIconSecondary.color,
                        alignment: .center
                    ),
                    tapCommand: Command { [weak handler] in
                        await handler?.handleTapRetry()
                    }
                )
            )
        case .loaded:
            guard !data.categories.isEmpty else {
                return .empty(
                    .init(
                        text: L10n.expenseCategoryPickerEmpty,
                        font: Typography.typographyMedium14,
                        textColor: Asset.Colors.textAndIconPlaceseholder.color,
                        alignment: .center,
                        numberOfLines: 0,
                        lineBreakMode: .byWordWrapping
                    )
                )
            }

            return .loaded(rows: rows)
        }
    }

    func makeRows(
        from data: ExpenseCategoryPickerFetchData
    ) -> [ExpenseCategoryPickerViewModel.RowViewModel] {
        switch data.loadingState {
        case .idle, .loading:
            return (0..<Constants.loadingRowsCount).map { _ in
                ExpenseCategoryPickerViewModel.RowViewModel(isLoading: true)
            }
        case .failed:
            return []
        case .loaded:
            return data.categories.map { category in
                ExpenseCategoryPickerViewModel.RowViewModel(
                    id: category.id,
                    iconText: category.icon,
                    title: .init(
                        text: category.name,
                        font: Typography.typographySemibold16,
                        textColor: Asset.Colors.textAndIconPrimary.color,
                        alignment: .left
                    ),
                    iconBackgroundColor: colorProvider.summaryColor(for: category.color),
                    isSelected: data.selectedCategoryID == category.id,
                    tapCommand: Command { [weak handler] in
                        await handler?.handleTapCategory(id: category.id)
                    }
                )
            }
        }
    }
}
