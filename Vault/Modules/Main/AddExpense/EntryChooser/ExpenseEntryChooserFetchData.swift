import Foundation

struct ExpenseEntryChooserFetchData: Sendable {
    let title: String

    init(title: String = L10n.mainAddExpenseTitle) {
        self.title = title
    }
}
