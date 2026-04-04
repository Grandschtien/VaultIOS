import Foundation

struct ExpenseManualEntryFetchData: Sendable {
    let title: String
    let loadingState: LoadingStatus
    let isConfirmEnabled: Bool
    let currencyCode: String
    let amountText: String
    let titleText: String
    let descriptionText: String
    let selectedCategory: ExpenseCategorySelectionModel?

    init(
        title: String = L10n.expenseManualEntryTitle,
        loadingState: LoadingStatus = .idle,
        isConfirmEnabled: Bool = false,
        currencyCode: String = "USD",
        amountText: String = "",
        titleText: String = "",
        descriptionText: String = "",
        selectedCategory: ExpenseCategorySelectionModel? = nil
    ) {
        self.title = title
        self.loadingState = loadingState
        self.isConfirmEnabled = isConfirmEnabled
        self.currencyCode = currencyCode
        self.amountText = amountText
        self.titleText = titleText
        self.descriptionText = descriptionText
        self.selectedCategory = selectedCategory
    }
}
