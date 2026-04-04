import Foundation

struct ExpenseEntryChooserViewModel: Equatable {
    let header: AddExpenseSheetHeaderView.ViewModel
    let aiButton: Button.ButtonViewModel
    let manualButton: Button.ButtonViewModel

    init(
        header: AddExpenseSheetHeaderView.ViewModel = .init(),
        aiButton: Button.ButtonViewModel = .init(),
        manualButton: Button.ButtonViewModel = .init()
    ) {
        self.header = header
        self.aiButton = aiButton
        self.manualButton = manualButton
    }
}
