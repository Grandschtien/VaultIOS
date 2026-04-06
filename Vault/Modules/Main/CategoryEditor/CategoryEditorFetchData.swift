import Foundation

struct CategoryEditorFetchData: Sendable {
    let mode: CategoryEditorMode
    let loadingState: LoadingStatus
    let draft: CategoryEditorDraft
    let prefilledCustomEmoji: String?
    let prefilledCustomColorHex: String?
    let isPrimaryEnabled: Bool
    let isPrimaryLoading: Bool
    let isDeleteVisible: Bool
    let isDeleteLoading: Bool
    let shouldShowNameError: Bool

    init(
        mode: CategoryEditorMode,
        loadingState: LoadingStatus = .idle,
        draft: CategoryEditorDraft,
        prefilledCustomEmoji: String? = nil,
        prefilledCustomColorHex: String? = nil,
        isPrimaryEnabled: Bool = false,
        isPrimaryLoading: Bool = false,
        isDeleteVisible: Bool = false,
        isDeleteLoading: Bool = false,
        shouldShowNameError: Bool = false
    ) {
        self.mode = mode
        self.loadingState = loadingState
        self.draft = draft
        self.prefilledCustomEmoji = prefilledCustomEmoji
        self.prefilledCustomColorHex = prefilledCustomColorHex
        self.isPrimaryEnabled = isPrimaryEnabled
        self.isPrimaryLoading = isPrimaryLoading
        self.isDeleteVisible = isDeleteVisible
        self.isDeleteLoading = isDeleteLoading
        self.shouldShowNameError = shouldShowNameError
    }
}
