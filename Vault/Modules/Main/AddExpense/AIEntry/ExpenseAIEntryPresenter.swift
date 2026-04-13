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
        let isLoading = data.loadingState == .loading
        let isRecording = data.voiceRecordingState == .recording

        viewModel = ExpenseAIEntryViewModel(
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
                isEditable: data.isPromptEditable,
                onTextDidChange: CommandOf { [weak handler] text in
                    await handler?.handleChangePrompt(text)
                }
            ),
            voiceButton: .init(
                title: isRecording ? L10n.expenseAiEntryVoiceRecording : "",
                icon: UIImage(systemName: "mic.fill"),
                isRecording: isRecording,
                isEnabled: !isLoading,
                startRecordingCommand: Command { [weak handler] in
                    await handler?.handleStartVoiceRecording()
                },
                stopRecordingCommand: Command { [weak handler] in
                    await handler?.handleStopVoiceRecording()
                }
            ),
            processButton: .init(
                title: L10n.expenseAiEntryProcess,
                titleColor: Asset.Colors.textAndIconPrimaryInverted.color,
                backgroundColor: Asset.Colors.interactiveElemetsPrimary.color,
                font: Typography.typographySemibold16,
                isEnabled: data.isProcessEnabled && !isLoading,
                isLoading: isLoading,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapProcess()
                }
            )
        )
    }
}
