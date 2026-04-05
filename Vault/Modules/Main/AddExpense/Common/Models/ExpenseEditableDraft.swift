import Foundation

struct ExpenseEditableDraft: Equatable, Sendable {
    var amountText: String
    var titleText: String
    var descriptionText: String
    var selectedCategory: ExpenseCategorySelectionModel?
    var currencyCode: String

    init(
        amountText: String = "",
        titleText: String = "",
        descriptionText: String = "",
        selectedCategory: ExpenseCategorySelectionModel? = nil,
        currencyCode: String = "USD"
    ) {
        self.amountText = amountText
        self.titleText = titleText
        self.descriptionText = descriptionText
        self.selectedCategory = selectedCategory
        self.currencyCode = currencyCode
    }
}
