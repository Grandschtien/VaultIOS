import Foundation

struct ExpenseAIEntryFetchData: Sendable {
    let title: String
    let promptText: String
    let maximumCharacters: Int
    let loadingState: LoadingStatus
    let isPromptEditable: Bool
    let isCloseEnabled: Bool
    let isProcessEnabled: Bool

    init(
        title: String = L10n.expenseAiEntryTitle,
        promptText: String = "",
        maximumCharacters: Int = 280,
        loadingState: LoadingStatus = .idle,
        isPromptEditable: Bool = true,
        isCloseEnabled: Bool = true,
        isProcessEnabled: Bool = false
    ) {
        self.title = title
        self.promptText = promptText
        self.maximumCharacters = maximumCharacters
        self.loadingState = loadingState
        self.isPromptEditable = isPromptEditable
        self.isCloseEnabled = isCloseEnabled
        self.isProcessEnabled = isProcessEnabled
    }
}
