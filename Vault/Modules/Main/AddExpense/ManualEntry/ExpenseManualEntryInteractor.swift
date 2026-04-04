import Foundation

protocol ExpenseManualEntryBusinessLogic: Sendable {
    func fetchData() async
}

protocol ExpenseManualEntryHandler: AnyObject, Sendable {
    func handleChangeAmount(_ text: String) async
    func handleChangeTitle(_ text: String) async
    func handleChangeDescription(_ text: String) async
    func handleTapCategory() async
    func handleTapConfirm() async
    func handleTapClose() async
}

actor ExpenseManualEntryInteractor: ExpenseManualEntryBusinessLogic {
    private let presenter: ExpenseManualEntryPresentationLogic
    private let router: ExpenseManualEntryRoutingLogic
    private let repository: MainFlowDomainRepositoryProtocol
    private let observer: MainFlowDomainObserverProtocol
    private let userProfileStorageService: UserProfileStorageServiceProtocol
    private let requestBuilder: ExpenseManualEntryRequestBuilder

    private var amountText: String = ""
    private var titleText: String = ""
    private var descriptionText: String = ""
    private var selectedCategory: ExpenseCategorySelectionModel?
    private var loadingState: LoadingStatus = .idle

    init(
        presenter: ExpenseManualEntryPresentationLogic,
        router: ExpenseManualEntryRoutingLogic,
        repository: MainFlowDomainRepositoryProtocol,
        observer: MainFlowDomainObserverProtocol,
        userProfileStorageService: UserProfileStorageServiceProtocol,
        requestBuilder: ExpenseManualEntryRequestBuilder
    ) {
        self.presenter = presenter
        self.router = router
        self.repository = repository
        self.observer = observer
        self.userProfileStorageService = userProfileStorageService
        self.requestBuilder = requestBuilder
    }

    func fetchData() async {
        await presentFetchedData()
    }
}

private extension ExpenseManualEntryInteractor {
    func presentFetchedData() async {
        await presenter.presentFetchedData(
            ExpenseManualEntryFetchData(
                loadingState: loadingState,
                isConfirmEnabled: isConfirmEnabled(),
                currencyCode: currentCurrencyCode(),
                amountText: amountText,
                titleText: titleText,
                descriptionText: descriptionText,
                selectedCategory: selectedCategory
            )
        )
    }

    func isConfirmEnabled() -> Bool {
        requestBuilder.isValidDraft(
            amountText: amountText,
            titleText: titleText,
            selectedCategory: selectedCategory
        )
    }

    func makeRequest(timeOfAdd: Date) -> ExpensesCreateRequestDTO? {
        requestBuilder.makeRequest(
            amountText: amountText,
            titleText: titleText,
            descriptionText: descriptionText,
            selectedCategory: selectedCategory,
            currencyCode: currentCurrencyCode(),
            timeOfAdd: timeOfAdd
        )
    }

    func currentCurrencyCode() -> String {
        userProfileStorageService.loadProfile()?.currency
            ?? observer.currentOverviewSnapshot().summary?.currency
            ?? observer.currentCategoriesSnapshot().categories.first?.currency
            ?? Locale.current.currency?.identifier
            ?? "USD"
    }

    func resetLoadingStateIfNeeded() {
        guard loadingState != .loading else {
            return
        }

        loadingState = .idle
    }
}

extension ExpenseManualEntryInteractor: ExpenseManualEntryHandler {
    func handleChangeAmount(_ text: String) async {
        amountText = text
        resetLoadingStateIfNeeded()
        await presentFetchedData()
    }

    func handleChangeTitle(_ text: String) async {
        titleText = text
        resetLoadingStateIfNeeded()
        await presentFetchedData()
    }

    func handleChangeDescription(_ text: String) async {
        descriptionText = text
        resetLoadingStateIfNeeded()
        await presentFetchedData()
    }

    func handleTapCategory() async {
        await router.openCategoryPicker(
            selectedCategoryID: selectedCategory?.id,
            output: self
        )
    }

    func handleTapConfirm() async {
        guard loadingState != .loading,
              let request = makeRequest(timeOfAdd: Date()) else {
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

    func handleTapClose() async {
        await router.close()
    }
}

extension ExpenseManualEntryInteractor: ExpenseCategoryPickerOutput {
    func handleDidSelectCategory(_ category: ExpenseCategorySelectionModel) async {
        selectedCategory = category
        resetLoadingStateIfNeeded()
        await presentFetchedData()
    }
}
