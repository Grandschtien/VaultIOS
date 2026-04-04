import UIKit
internal import Combine

@MainActor
protocol ExpenseManualEntryPresentationLogic: Sendable {
    func presentFetchedData(_ data: ExpenseManualEntryFetchData)
}

final class ExpenseManualEntryPresenter: ExpenseManualEntryPresentationLogic, LayoutScaleProviding {
    @Published
    private(set) var viewModel: ExpenseManualEntryViewModel

    weak var handler: ExpenseManualEntryHandler?

    private let colorProvider: CategoryColorProviding

    init(
        viewModel: ExpenseManualEntryViewModel,
        colorProvider: CategoryColorProviding
    ) {
        self.viewModel = viewModel
        self.colorProvider = colorProvider
    }

    func presentFetchedData(_ data: ExpenseManualEntryFetchData) {
        viewModel = ExpenseManualEntryViewModel(
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
            amountInput: .init(
                title: .init(
                    text: L10n.expenseManualEntryAmountLabel,
                    font: Typography.typographyMedium12,
                    textColor: Asset.Colors.textAndIconPlaceseholder.color,
                    alignment: .center
                ),
                text: data.amountText,
                placeholder: L10n.expenseManualEntryAmountPlaceholder,
                onTextDidChange: CommandOf { [weak handler] text in
                    await handler?.handleChangeAmount(text)
                }
            ),
            titleField: .init(
                text: data.titleText,
                placeholder: L10n.expenseManualEntryTitlePlaceholder,
                titleText: L10n.expenseManualEntryTitleLabel,
                onTextDidChanged: CommandOf { [weak handler] text in
                    await handler?.handleChangeTitle(text)
                }
            ),
            categoryField: makeCategoryFieldViewModel(selectedCategory: data.selectedCategory),
            descriptionInput: .init(
                title: .init(
                    text: L10n.expenseManualEntryDescriptionLabel,
                    font: Typography.typographyMedium14,
                    textColor: Asset.Colors.textAndIconPrimary.color,
                    alignment: .left
                ),
                text: data.descriptionText,
                placeholder: L10n.expenseManualEntryDescriptionPlaceholder,
                minimumHeight: sizeXXL,
                onTextDidChange: CommandOf { [weak handler] text in
                    await handler?.handleChangeDescription(text)
                }
            ),
            confirmButton: .init(
                title: L10n.expenseManualEntryConfirmChanges,
                titleColor: Asset.Colors.textAndIconPrimaryInverted.color,
                backgroundColor: Asset.Colors.interactiveElemetsPrimary.color,
                font: Typography.typographySemibold16,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapConfirm()
                },
                leftIcon: UIImage(systemName: "checkmark")
            )
        )
    }
}

private extension ExpenseManualEntryPresenter {
    func makeCategoryFieldViewModel(
        selectedCategory: ExpenseCategorySelectionModel?
    ) -> ExpenseCategoryFieldView.ViewModel {
        let iconBackgroundColor: UIColor
        if let selectedCategory {
            iconBackgroundColor = colorProvider.summaryColor(for: selectedCategory.color)
        } else {
            iconBackgroundColor = Asset.Colors.interactiveInputBackground.color
        }

        return ExpenseCategoryFieldView.ViewModel(
            title: .init(
                text: L10n.expenseManualEntryCategoryLabel,
                font: Typography.typographyMedium14,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .left
            ),
            value: .init(
                text: selectedCategory?.name ?? L10n.expenseManualEntryCategoryPlaceholder,
                font: selectedCategory == nil ? Typography.typographyRegular16 : Typography.typographySemibold16,
                textColor: selectedCategory == nil
                    ? Asset.Colors.textAndIconPlaceseholder.color
                    : Asset.Colors.textAndIconPrimary.color,
                alignment: .left
            ),
            iconText: selectedCategory?.icon,
            iconBackgroundColor: iconBackgroundColor,
            tapCommand: Command { [weak handler] in
                await handler?.handleTapCategory()
            }
        )
    }
}
