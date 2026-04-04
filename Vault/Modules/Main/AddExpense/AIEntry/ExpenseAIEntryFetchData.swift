import Foundation

struct ExpenseAIEntryFetchData: Sendable {
    let title: String
    let promptText: String
    let maximumCharacters: Int

    init(
        title: String = L10n.expenseAiEntryTitle,
        promptText: String = "",
        maximumCharacters: Int = 280
    ) {
        self.title = title
        self.promptText = promptText
        self.maximumCharacters = maximumCharacters
    }
}
