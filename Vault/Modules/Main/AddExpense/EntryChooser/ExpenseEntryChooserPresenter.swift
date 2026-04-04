import UIKit
internal import Combine

@MainActor
protocol ExpenseEntryChooserPresentationLogic: Sendable {
    func presentFetchedData(_ data: ExpenseEntryChooserFetchData)
}

final class ExpenseEntryChooserPresenter: ExpenseEntryChooserPresentationLogic {
    @Published
    private(set) var viewModel: ExpenseEntryChooserViewModel

    weak var handler: ExpenseEntryChooserHandler?

    init(viewModel: ExpenseEntryChooserViewModel) {
        self.viewModel = viewModel
    }

    func presentFetchedData(_ data: ExpenseEntryChooserFetchData) {
        viewModel = ExpenseEntryChooserViewModel(
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
            aiButton: .init(
                title: L10n.expenseEntryChooserEnterWithAi,
                titleColor: Asset.Colors.textAndIconPrimaryInverted.color,
                backgroundColor: Asset.Colors.interactiveElemetsPrimary.color,
                font: Typography.typographySemibold16,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapAiEntry()
                },
                leftIcon: UIImage(systemName: "sparkles")
            ),
            manualButton: .init(
                title: L10n.expenseEntryChooserEnterManually,
                titleColor: Asset.Colors.textAndIconPrimary.color,
                backgroundColor: Asset.Colors.interactiveInputBackground.color,
                font: Typography.typographySemibold16,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapManualEntry()
                },
                leftIcon: UIImage(systemName: "square.and.pencil"),
                iconTintColor: Asset.Colors.textAndIconPrimary.color
            )
        )
    }
}
