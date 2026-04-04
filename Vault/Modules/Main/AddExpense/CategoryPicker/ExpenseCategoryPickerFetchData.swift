import Foundation

struct ExpenseCategoryPickerFetchData: Sendable {
    let title: String
    let loadingState: LoadingStatus
    let categories: [ExpenseCategorySelectionModel]
    let selectedCategoryID: String?

    init(
        title: String = L10n.mainOverviewCategories,
        loadingState: LoadingStatus = .idle,
        categories: [ExpenseCategorySelectionModel] = [],
        selectedCategoryID: String? = nil
    ) {
        self.title = title
        self.loadingState = loadingState
        self.categories = categories
        self.selectedCategoryID = selectedCategoryID
    }
}
