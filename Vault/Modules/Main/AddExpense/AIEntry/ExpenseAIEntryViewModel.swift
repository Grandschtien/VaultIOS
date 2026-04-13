import Foundation

struct ExpenseAIEntryViewModel: Equatable {
    let header: AddExpenseSheetHeaderView.ViewModel
    let promptInput: ExpenseMultilineInputView.ViewModel
    let voiceButton: ExpenseAIEntryVoiceButtonView.ViewModel
    let processButton: Button.ButtonViewModel

    init(
        header: AddExpenseSheetHeaderView.ViewModel = .init(),
        promptInput: ExpenseMultilineInputView.ViewModel = .init(),
        voiceButton: ExpenseAIEntryVoiceButtonView.ViewModel = .init(),
        processButton: Button.ButtonViewModel = .init()
    ) {
        self.header = header
        self.promptInput = promptInput
        self.voiceButton = voiceButton
        self.processButton = processButton
    }
}
