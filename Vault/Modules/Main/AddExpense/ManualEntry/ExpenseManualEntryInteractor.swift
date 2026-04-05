import Foundation

protocol ExpenseManualEntryBusinessLogic: Sendable {
    func fetchData() async
}

protocol ExpenseManualEntryHandler: AnyObject, Sendable {
    func handleChangeAmount(_ text: String) async
    func handleChangeTitle(_ text: String) async
    func handleChangeDescription(_ text: String) async
    func handleChangeCurrentPage(_ page: Int) async
    func handleTapCategory() async
    func handleTapPrimaryButton() async
    func handleTapSkip() async
    func handleTapClose() async
}

actor ExpenseManualEntryInteractor: ExpenseManualEntryBusinessLogic {
    private enum DraftStatus: Sendable {
        case pending
        case included
        case skipped
    }

    private let presenter: ExpenseManualEntryPresentationLogic
    private let router: ExpenseManualEntryRoutingLogic
    private let repository: MainFlowDomainRepositoryProtocol
    private let currencyCodeResolver: AddExpenseCurrencyCodeResolver
    private let requestBuilder: ExpenseManualEntryRequestBuilder

    private var drafts: [ExpenseEditableDraft]
    private var draftStatuses: [DraftStatus]
    private var currentDraftIndex: Int
    
    var currentDraft: ExpenseEditableDraft {
        drafts[currentDraftIndex]
    }

    private var loadingState: LoadingStatus = .idle

    init(
        presenter: ExpenseManualEntryPresentationLogic,
        router: ExpenseManualEntryRoutingLogic,
        repository: MainFlowDomainRepositoryProtocol,
        currencyCodeResolver: AddExpenseCurrencyCodeResolver,
        requestBuilder: ExpenseManualEntryRequestBuilder,
        initialDrafts: [ExpenseEditableDraft]
    ) {
        let resolvedCurrencyCode = currencyCodeResolver.resolve()
        let normalizedDrafts = Self.makeInitialDrafts(
            from: initialDrafts,
            currencyCode: resolvedCurrencyCode
        )

        self.presenter = presenter
        self.router = router
        self.repository = repository
        self.currencyCodeResolver = currencyCodeResolver
        self.requestBuilder = requestBuilder
        self.currentDraftIndex = 0
        self.drafts = normalizedDrafts
        self.draftStatuses = drafts.map { _ in .pending }
    }

    func fetchData() async {
        await presentFetchedData()
    }
}

private extension ExpenseManualEntryInteractor {
    static func makeInitialDrafts(
        from initialDrafts: [ExpenseEditableDraft],
        currencyCode: String
    ) -> [ExpenseEditableDraft] {
        guard !initialDrafts.isEmpty else {
            return [.init(currencyCode: currencyCode)]
        }

        return initialDrafts.map { draft in
            let normalizedCurrencyCode = draft.currencyCode
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()

            guard normalizedCurrencyCode.isEmpty else {
                return draft
            }

            var updatedDraft = draft
            updatedDraft.currencyCode = currencyCode
            return updatedDraft
        }
    }

    func presentFetchedData() async {
        let fallbackDraft = ExpenseEditableDraft(
            currencyCode: currencyCodeResolver.resolve()
        )
        let hasCurrentDraft = drafts.indices.contains(currentDraftIndex)

        await presenter.presentFetchedData(
            ExpenseManualEntryFetchData(
                loadingState: loadingState,
                currentDraft: hasCurrentDraft ? currentDraft : fallbackDraft,
                primaryAction: drafts.count > 1 && currentDraftIndex < drafts.count - 1 ? .next : .confirm,
                isPrimaryEnabled: hasCurrentDraft ? isCurrentDraftValid() : false,
                isSkipVisible: drafts.count > 1 && currentDraftIndex < drafts.count - 1,
                isCloseEnabled: loadingState != .loading
            )
        )
    }

    func isCurrentDraftValid() -> Bool {
        return requestBuilder.isValidDraft(currentDraft)
    }

    func updateCurrentDraft(
        _ mutation: (inout ExpenseEditableDraft) -> Void
    ) {
        mutation(&drafts[currentDraftIndex])
    }

    func resetLoadingStateIfNeeded() {
        guard loadingState != .loading else {
            return
        }

        loadingState = .idle
    }

    func advanceToNextPageIfPossible() {
        guard currentDraftIndex < drafts.count - 1 else {
            return
        }

        currentDraftIndex += 1
    }

    func indicesToSaveForFinalConfirmation() -> [Int] {
        var indices = draftStatuses.enumerated().compactMap { index, status in
            status == .included ? index : nil
        }

        if draftStatuses.indices.contains(currentDraftIndex),
           draftStatuses[currentDraftIndex] != .skipped {
            indices.append(currentDraftIndex)
        }

        return Array(Set(indices)).sorted()
    }

    func firstInvalidIncludedPage() -> Int? {
        indicesToSaveForFinalConfirmation().first { index in
            drafts.indices.contains(index) && !requestBuilder.isValidDraft(drafts[index])
        }
    }
}

extension ExpenseManualEntryInteractor: ExpenseManualEntryHandler {
    func handleChangeAmount(_ text: String) async {
        updateCurrentDraft { $0.amountText = text }
        resetLoadingStateIfNeeded()
        await presentFetchedData()
    }

    func handleChangeTitle(_ text: String) async {
        updateCurrentDraft { $0.titleText = text }
        resetLoadingStateIfNeeded()
        await presentFetchedData()
    }

    func handleChangeDescription(_ text: String) async {
        updateCurrentDraft { $0.descriptionText = text }
        resetLoadingStateIfNeeded()
        await presentFetchedData()
    }

    func handleChangeCurrentPage(_ page: Int) async {
        guard drafts.indices.contains(page),
              page != currentDraftIndex else {
            return
        }

        currentDraftIndex = page
        resetLoadingStateIfNeeded()
        await presentFetchedData()
    }

    func handleTapCategory() async {
        guard loadingState != .loading else {
            return
        }

        await router.openCategoryPicker(
            selectedCategoryID: currentDraft.selectedCategory?.id,
            output: self
        )
    }

    func handleTapPrimaryButton() async {
        guard loadingState != .loading else {
            return
        }

        if currentDraftIndex < drafts.count - 1 {
            guard isCurrentDraftValid() else {
                return
            }

            draftStatuses[currentDraftIndex] = .included
            advanceToNextPageIfPossible()
            await presentFetchedData()
            return
        }

        if let invalidPage = firstInvalidIncludedPage() {
            currentDraftIndex = invalidPage
            await presentFetchedData()
            return
        }

        guard isCurrentDraftValid() else {
            return
        }

        draftStatuses[currentDraftIndex] = .included
        let draftsToSave = indicesToSaveForFinalConfirmation().compactMap { index in
            drafts.indices.contains(index) ? drafts[index] : nil
        }

        guard !draftsToSave.isEmpty else {
            await router.close()
            return
        }

        guard let request = requestBuilder.makeRequest(
            drafts: draftsToSave,
            timeOfAdd: Date()
        ) else {
            if let invalidPage = firstInvalidIncludedPage() {
                currentDraftIndex = invalidPage
                await presentFetchedData()
            }
            return
        }

        loadingState = .loading
        await presentFetchedData()

        do {
            try await repository.addExpense(request)
            await router.close()
        } catch {
            loadingState = .failed(.undelinedError(description: L10n.mainOverviewError))
            await presentFetchedData()
            await router.presentError(with: L10n.mainOverviewError)
        }
    }

    func handleTapSkip() async {
        guard loadingState != .loading,
              currentDraftIndex < drafts.count - 1,
              draftStatuses.indices.contains(currentDraftIndex) else {
            return
        }

        draftStatuses[currentDraftIndex] = .skipped
        advanceToNextPageIfPossible()
        await presentFetchedData()
    }

    func handleTapClose() async {
        guard loadingState != .loading else {
            return
        }

        await router.close()
    }
}

extension ExpenseManualEntryInteractor: ExpenseCategoryPickerOutput {
    func handleDidSelectCategory(_ category: ExpenseCategorySelectionModel) async {
        updateCurrentDraft { $0.selectedCategory = category }
        resetLoadingStateIfNeeded()
        await presentFetchedData()
    }
}
