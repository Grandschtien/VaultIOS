import Foundation

struct ExpenseManualEntryViewModel: Equatable {
    let header: AddExpenseSheetHeaderView.ViewModel
    let currentDraft: ExpenseManualEntryView.DraftViewModel?
    let changePageCommand: CommandOf<Int>
    let primaryButton: Button.ButtonViewModel
    let skipButton: Button.ButtonViewModel?

    init(
        header: AddExpenseSheetHeaderView.ViewModel = .init(),
        currentDraft: ExpenseManualEntryView.DraftViewModel? = .init(),
        changePageCommand: CommandOf<Int> = .init(action: nil),
        primaryButton: Button.ButtonViewModel = .init(),
        skipButton: Button.ButtonViewModel? = nil
    ) {
        self.header = header
        self.currentDraft = currentDraft
        self.changePageCommand = changePageCommand
        self.primaryButton = primaryButton
        self.skipButton = skipButton
    }
}
