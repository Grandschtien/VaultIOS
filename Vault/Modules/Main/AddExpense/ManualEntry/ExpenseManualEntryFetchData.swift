import Foundation

struct ExpenseManualEntryFetchData: Sendable {
    let title: String
    let amountText: String
    let titleText: String
    let descriptionText: String
    let selectedCategory: ExpenseCategorySelectionModel?

    init(
        title: String = L10n.expenseManualEntryTitle,
        amountText: String = "",
        titleText: String = "",
        descriptionText: String = "",
        selectedCategory: ExpenseCategorySelectionModel? = nil
    ) {
        self.title = title
        self.amountText = amountText
        self.titleText = titleText
        self.descriptionText = descriptionText
        self.selectedCategory = selectedCategory
    }
}
