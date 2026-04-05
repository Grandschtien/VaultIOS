import Foundation

struct ExpenseManualEntryFetchData: Sendable {
    enum PrimaryAction: Sendable, Equatable {
        case next
        case confirm
    }

    let title: String
    let loadingState: LoadingStatus
    let currentDraft: ExpenseEditableDraft?
    let primaryAction: PrimaryAction
    let isPrimaryEnabled: Bool
    let isSkipVisible: Bool
    let isCloseEnabled: Bool

    init(
        title: String = L10n.expenseManualEntryTitle,
        loadingState: LoadingStatus = .idle,
        currentDraft: ExpenseEditableDraft? = .init(),
        primaryAction: PrimaryAction = .confirm,
        isPrimaryEnabled: Bool = false,
        isSkipVisible: Bool = false,
        isCloseEnabled: Bool = true
    ) {
        self.title = title
        self.loadingState = loadingState
        self.currentDraft = currentDraft
        self.primaryAction = primaryAction
        self.isPrimaryEnabled = isPrimaryEnabled
        self.isSkipVisible = isSkipVisible
        self.isCloseEnabled = isCloseEnabled
    }
}
