import Foundation

protocol CategoryEditorBusinessLogic: Sendable {
    func fetchData() async
}

protocol CategoryEditorHandler: AnyObject, Sendable {
    func handleChangeCategoryName(_ text: String) async
    func handleTapEmojiPreset(_ emoji: String) async
    func handleTapCustomEmojiButton() async
    func handleTapColorPreset(_ hex: String) async
    func handleTapCustomColorButton() async
    func handleTapPrimaryButton() async
    func handleTapDeleteButton() async
    func handleTapBackButton() async
    func handleTapRetryButton() async
}

protocol CategoryEditorSystemPickerOutput: AnyObject, Sendable {
    func handleDidSelectCustomColor(_ hex: String) async
}

actor CategoryEditorInteractor: CategoryEditorBusinessLogic {
    private let mode: CategoryEditorMode
    private let presenter: CategoryEditorPresentationLogic
    private let router: CategoryEditorRoutingLogic
    private let repository: MainFlowDomainRepositoryProtocol
    private let observer: MainFlowDomainObserverProtocol
    private let subscriptionAccessService: SubscriptionAccessServicing
    private let subscriptionLimitErrorResolver: CategoryEditorSubscriptionLimitErrorResolving
    private let presetProvider: CategoryEditorPresetProviding
    private let colorProvider: CategoryColorProviding

    private var loadingState: LoadingStatus = .idle
    private var draft: CategoryEditorDraft
    private var originalDraft: CategoryEditorDraft?
    private var isPrimaryLoading = false
    private var isDeleteLoading = false
    private var shouldShowNameError = false

    init(
        mode: CategoryEditorMode,
        presenter: CategoryEditorPresentationLogic,
        router: CategoryEditorRoutingLogic,
        repository: MainFlowDomainRepositoryProtocol,
        observer: MainFlowDomainObserverProtocol,
        subscriptionAccessService: SubscriptionAccessServicing,
        subscriptionLimitErrorResolver: CategoryEditorSubscriptionLimitErrorResolving,
        presetProvider: CategoryEditorPresetProviding,
        colorProvider: CategoryColorProviding
    ) {
        let initialDraft = CategoryEditorDraft(
            name: "",
            emoji: presetProvider.defaultEmoji,
            colorHex: presetProvider.defaultColorHex
        )

        self.mode = mode
        self.presenter = presenter
        self.router = router
        self.repository = repository
        self.observer = observer
        self.subscriptionAccessService = subscriptionAccessService
        self.subscriptionLimitErrorResolver = subscriptionLimitErrorResolver
        self.presetProvider = presetProvider
        self.colorProvider = colorProvider
        self.draft = initialDraft
    }

    func fetchData() async {
        switch mode {
        case .create:
            loadingState = .loaded
            await presentFetchedData()
        case let .edit(id):
            loadingState = .loading
            await presentFetchedData()

            if await loadCategory(id: id) {
                loadingState = .loaded
            } else {
                loadingState = .failed(.undelinedError(description: L10n.mainOverviewError))
            }

            await presentFetchedData()
        }
    }
}

private extension CategoryEditorInteractor {
    func presentFetchedData() async {
        await presenter.presentFetchedData(
            CategoryEditorFetchData(
                mode: mode,
                loadingState: loadingState,
                draft: draft,
                prefilledCustomEmoji: prefilledCustomEmoji(),
                prefilledCustomColorHex: prefilledCustomColorHex(),
                isPrimaryEnabled: isPrimaryEnabled(),
                isPrimaryLoading: isPrimaryLoading,
                isDeleteVisible: canDeleteCategory(),
                isDeleteLoading: isDeleteLoading,
                shouldShowNameError: shouldShowNameError
            )
        )
    }

    func loadCategory(id: String) async -> Bool {
        if let category = resolveCategory(id: id) {
            applyCategory(category)
            return true
        }

        do {
            try await repository.refreshCategories()
        } catch { }

        if let category = resolveCategory(id: id) {
            applyCategory(category)
            return true
        }

        do {
            try await repository.refreshCategoryFirstPage(id: id)
        } catch { }

        if let category = observer.currentCategorySnapshot(id: id).category {
            applyCategory(category)
            return true
        }

        return false
    }

    func resolveCategory(id: String) -> MainCategoryCardModel? {
        observer.currentCategorySnapshot(id: id).category
            ?? observer.currentCategoriesSnapshot().categories.first(where: { $0.id == id })
    }

    func applyCategory(_ category: MainCategoryCardModel) {
        let nextDraft = CategoryEditorDraft(
            name: category.name,
            emoji: category.icon,
            colorHex: colorProvider.normalizedHex(from: category.color) ?? presetProvider.defaultColorHex
        )

        draft = nextDraft
        originalDraft = nextDraft
    }

    func isPrimaryEnabled() -> Bool {
        guard loadingState == .loaded,
              !isPrimaryLoading,
              !isDeleteLoading,
              isDraftValid()
        else {
            return false
        }

        switch mode {
        case .create:
            return true
        case .edit:
            return draft != originalDraft
        }
    }

    func isDraftValid() -> Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !draft.emoji.isEmpty
            && !draft.colorHex.isEmpty
    }

    func makeRequest() -> CategoryCreateRequestDTO {
        CategoryCreateRequestDTO(
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: draft.emoji,
            color: draft.colorHex
        )
    }

    func prefilledCustomEmoji() -> String? {
        guard let originalDraft else {
            return nil
        }

        let emoji = originalDraft.emoji
        return presetProvider.emojiPresets().contains(emoji) ? nil : emoji
    }

    func prefilledCustomColorHex() -> String? {
        guard let originalDraft else {
            return nil
        }

        let hex = originalDraft.colorHex
        return presetProvider.colorPresets().contains(hex) ? nil : hex
    }

    func canDeleteCategory() -> Bool {
        guard mode.categoryID != nil else {
            return false
        }

        let normalizedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalizedName.compare(L10n.other, options: [.caseInsensitive]) != .orderedSame
            && normalizedName.compare("Unmapped", options: [.caseInsensitive]) != .orderedSame
    }

    func handleCreateCategoryError(_ error: Error) async {
        guard subscriptionLimitErrorResolver.isSubscriptionLimitError(error) else {
            await router.presentError(with: L10n.mainOverviewError)
            return
        }

        let currentTier = await subscriptionAccessService.currentTier()
        await router.openSubscription(
            currentTier: currentTier,
            output: self
        )
    }
}

extension CategoryEditorInteractor: CategoryEditorHandler {
    func handleChangeCategoryName(_ text: String) async {
        draft = CategoryEditorDraft(
            name: text,
            emoji: draft.emoji,
            colorHex: draft.colorHex
        )
        if shouldShowNameError {
            shouldShowNameError = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        await presentFetchedData()
    }

    func handleTapEmojiPreset(_ emoji: String) async {
        draft = CategoryEditorDraft(
            name: draft.name,
            emoji: emoji,
            colorHex: draft.colorHex
        )
        await presentFetchedData()
    }

    func handleTapCustomEmojiButton() async {
        guard loadingState == .loaded else {
            return
        }

        await router.openEmojiPicker(
            selectedEmoji: draft.emoji,
            output: self
        )
    }

    func handleTapColorPreset(_ hex: String) async {
        draft = CategoryEditorDraft(
            name: draft.name,
            emoji: draft.emoji,
            colorHex: hex
        )
        await presentFetchedData()
    }

    func handleTapCustomColorButton() async {
        guard loadingState == .loaded else {
            return
        }

        await router.openColorPicker(selectedHex: draft.colorHex)
    }

    func handleTapPrimaryButton() async {
        guard loadingState == .loaded,
              !isPrimaryLoading,
              !isDeleteLoading
        else {
            return
        }

        guard isDraftValid() else {
            shouldShowNameError = true
            await presentFetchedData()
            return
        }

        shouldShowNameError = false
        isPrimaryLoading = true
        await presentFetchedData()

        do {
            switch mode {
            case .create:
                _ = try await repository.addCategory(makeRequest())
            case let .edit(id):
                _ = try await repository.updateCategory(id: id, request: makeRequest())
            }

            isPrimaryLoading = false
            await presentFetchedData()
            await router.close()
        } catch {
            isPrimaryLoading = false
            await presentFetchedData()

            switch mode {
            case .create:
                await handleCreateCategoryError(error)
            case .edit:
                await router.presentError(with: L10n.mainOverviewError)
            }
        }
    }

    func handleTapDeleteButton() async {
        guard case let .edit(id) = mode,
              loadingState == .loaded,
              canDeleteCategory(),
              !isPrimaryLoading,
              !isDeleteLoading
        else {
            return
        }

        isDeleteLoading = true
        await presentFetchedData()

        do {
            try await repository.deleteCategory(id: id)
            isDeleteLoading = false
            await presentFetchedData()
            await router.close()
        } catch {
            isDeleteLoading = false
            await presentFetchedData()
            await router.presentError(with: L10n.mainOverviewError)
        }
    }

    func handleTapBackButton() async {
        guard !isPrimaryLoading, !isDeleteLoading else {
            return
        }

        await router.close()
    }

    func handleTapRetryButton() async {
        await fetchData()
    }
}

extension CategoryEditorInteractor: CategoryEmojiPickerOutput {
    func handleDidSelectEmoji(_ emoji: String) async {
        draft = CategoryEditorDraft(
            name: draft.name,
            emoji: emoji,
            colorHex: draft.colorHex
        )
        await presentFetchedData()
    }
}

extension CategoryEditorInteractor: CategoryEditorSystemPickerOutput {
    func handleDidSelectCustomColor(_ hex: String) async {
        draft = CategoryEditorDraft(
            name: draft.name,
            emoji: draft.emoji,
            colorHex: hex
        )
        await presentFetchedData()
    }
}

extension CategoryEditorInteractor: SubscriptionOutput {
    func handleSubscriptionDidSync() async {
        _ = await subscriptionAccessService.refreshCurrentTier()
    }
}
