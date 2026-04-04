import Foundation

struct ExpenseManualEntryViewModel: Equatable {
    let header: AddExpenseSheetHeaderView.ViewModel
    let amountInput: ExpenseAmountInputView.ViewModel
    let titleField: TextField.ViewModel
    let categoryField: ExpenseCategoryFieldView.ViewModel
    let descriptionInput: ExpenseMultilineInputView.ViewModel
    let confirmButton: Button.ButtonViewModel

    init(
        header: AddExpenseSheetHeaderView.ViewModel = .init(),
        amountInput: ExpenseAmountInputView.ViewModel = .init(),
        titleField: TextField.ViewModel = .init(),
        categoryField: ExpenseCategoryFieldView.ViewModel = .init(),
        descriptionInput: ExpenseMultilineInputView.ViewModel = .init(),
        confirmButton: Button.ButtonViewModel = .init()
    ) {
        self.header = header
        self.amountInput = amountInput
        self.titleField = titleField
        self.categoryField = categoryField
        self.descriptionInput = descriptionInput
        self.confirmButton = confirmButton
    }
}
