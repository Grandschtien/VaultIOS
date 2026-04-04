import UIKit
internal import Combine

@MainActor
protocol ExpenseAIEntryPresentationLogic: Sendable {
    func presentFetchedData(_ data: ExpenseAIEntryFetchData)
}

final class ExpenseAIEntryPresenter: ExpenseAIEntryPresentationLogic, LayoutScaleProviding {
    @Published
    private(set) var viewModel: ExpenseAIEntryViewModel

    weak var handler: ExpenseAIEntryHandler?

    init(viewModel: ExpenseAIEntryViewModel) {
        self.viewModel = viewModel
    }

    func presentFetchedData(_ data: ExpenseAIEntryFetchData) {
        viewModel = ExpenseAIEntryViewModel(
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
            promptInput: .init(
                text: data.promptText,
                placeholder: L10n.expenseAiEntryPlaceholder,
                counter: .init(
                    text: "\(data.promptText.count)/\(data.maximumCharacters)",
                    font: Typography.typographyMedium12,
                    textColor: Asset.Colors.textAndIconPlaceseholder.color,
                    alignment: .right
                ),
                minimumHeight: sizeXXXL,
                autocapitalizationType: .sentences,
                onTextDidChange: CommandOf { [weak handler] text in
                    await handler?.handleChangePrompt(text)
                }
            ),
            processButton: .init(
                title: L10n.expenseAiEntryProcess,
                titleColor: Asset.Colors.textAndIconPrimaryInverted.color,
                backgroundColor: Asset.Colors.interactiveElemetsPrimary.color,
                font: Typography.typographySemibold16,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapProcess()
                }
            )
        )
    }
}
