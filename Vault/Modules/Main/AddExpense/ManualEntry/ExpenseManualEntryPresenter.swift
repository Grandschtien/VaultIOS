import UIKit
internal import Combine

@MainActor
protocol ExpenseManualEntryPresentationLogic: Sendable {
    func presentFetchedData(_ data: ExpenseManualEntryFetchData)
}

final class ExpenseManualEntryPresenter: ExpenseManualEntryPresentationLogic, LayoutScaleProviding, ImageProviding {
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
        let isLoading = data.loadingState == .loading

        viewModel = ExpenseManualEntryViewModel(
            header: .init(
                title: .init(
                    text: data.title,
                    font: Typography.typographyBold20,
                    textColor: Asset.Colors.textAndIconPrimary.color,
                    alignment: .center
                ),
                isCloseEnabled: data.isCloseEnabled,
                closeCommand: Command { [weak handler] in
                    await handler?.handleTapClose()
                }
            ),
            currentDraft: makeFormViewModel(
                draft: data.currentDraft,
                isEditable: !isLoading
            ),
            changePageCommand: CommandOf { [weak handler] page in
                await handler?.handleChangeCurrentPage(page)
            },
            primaryButton: .init(
                title: primaryButtonTitle(for: data.primaryAction),
                titleColor: Asset.Colors.textAndIconPrimaryInverted.color,
                backgroundColor: Asset.Colors.interactiveElemetsPrimary.color,
                font: Typography.typographySemibold16,
                isEnabled: data.isPrimaryEnabled && !isLoading,
                isLoading: isLoading,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapPrimaryButton()
                },
                leftIcon: primaryButtonIcon(for: data.primaryAction)
            ),
            skipButton: data.isSkipVisible
                ? .init(
                    title: L10n.expenseManualEntrySkip,
                    titleColor: Asset.Colors.textAndIconPrimary.color,
                    backgroundColor: Asset.Colors.interactiveInputBackground.color,
                    font: Typography.typographySemibold16,
                    isEnabled: !isLoading,
                    tapCommand: Command { [weak handler] in
                        await handler?.handleTapSkip()
                    }
                )
                : nil
        )
    }
}

private extension ExpenseManualEntryPresenter {
    func makeFormViewModel(
        draft: ExpenseEditableDraft?,
        isEditable: Bool
    ) -> ExpenseManualEntryView.DraftViewModel? {
        guard let draft else { return nil }
        
        return ExpenseManualEntryView.DraftViewModel(
            amountInput: .init(
                title: .init(
                    text: L10n.expenseManualEntryAmountLabel,
                    font: Typography.typographyMedium12,
                    textColor: Asset.Colors.textAndIconPlaceseholder.color,
                    alignment: .center
                ),
                currencyLabel: .init(
                    text: amountCurrencyText(for: draft.currencyCode),
                    font: Typography.typographyBold36,
                    textColor: Asset.Colors.textAndIconPrimary.color
                ),
                text: draft.amountText,
                placeholder: L10n.expenseManualEntryAmountPlaceholder,
                isEnabled: isEditable,
                onTextDidChange: CommandOf { [weak handler] text in
                    await handler?.handleChangeAmount(text)
                }
            ),
            titleField: .init(
                text: draft.titleText,
                placeholder: L10n.expenseManualEntryTitlePlaceholder,
                titleText: L10n.expenseManualEntryTitleLabel,
                isEnabled: isEditable,
                onTextDidChanged: CommandOf { [weak handler] text in
                    await handler?.handleChangeTitle(text)
                }
            ),
            categoryField: makeCategoryFieldViewModel(
                selectedCategory: draft.selectedCategory,
                isEnabled: isEditable
            ),
            descriptionInput: .init(
                title: .init(
                    text: L10n.expenseManualEntryDescriptionLabel,
                    font: Typography.typographyMedium14,
                    textColor: Asset.Colors.textAndIconPrimary.color,
                    alignment: .left
                ),
                text: draft.descriptionText,
                placeholder: L10n.expenseManualEntryDescriptionPlaceholder,
                minimumHeight: sizeXXL,
                isEditable: isEditable,
                onTextDidChange: CommandOf { [weak handler] text in
                    await handler?.handleChangeDescription(text)
                }
            )
        )
    }

    func amountCurrencyText(for currencyCode: String) -> String {
        let normalizedCurrencyCode = currencyCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        guard !normalizedCurrencyCode.isEmpty else {
            return "USD"
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = normalizedCurrencyCode
        formatter.locale = Locale.current

        return formatter.currencySymbol ?? normalizedCurrencyCode
    }

    func makeCategoryFieldViewModel(
        selectedCategory: ExpenseCategorySelectionModel?,
        isEnabled: Bool
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
            isEnabled: isEnabled,
            tapCommand: Command { [weak handler] in
                await handler?.handleTapCategory()
            }
        )
    }

    func primaryButtonTitle(
        for action: ExpenseManualEntryFetchData.PrimaryAction
    ) -> String {
        switch action {
        case .next:
            return L10n.next
        case .confirm:
            return L10n.expenseManualEntryConfirmChanges
        }
    }

    func primaryButtonIcon(
        for action: ExpenseManualEntryFetchData.PrimaryAction
    ) -> UIImage? {
        switch action {
        case .next:
            return Asset.Icons.arrowRight.image
        case .confirm:
            return checkmarkImage
        }
    }
}
