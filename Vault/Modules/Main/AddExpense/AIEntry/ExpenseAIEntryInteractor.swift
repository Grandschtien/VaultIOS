import Foundation

protocol ExpenseAIEntryBusinessLogic: Sendable {
    func fetchData() async
}

protocol ExpenseAIEntryHandler: AnyObject, Sendable {
    func handleChangePrompt(_ text: String) async
    func handleTapProcess() async
    func handleTapClose() async
    func handleTapAddManually() async
    func handleTapFixPrompt() async
}

actor ExpenseAIEntryInteractor: ExpenseAIEntryBusinessLogic {
    private enum Constants {
        static let maximumCharacters = 280
        static let noExpenseDetected = "NO_EXPENSE_DETECTED"
    }

    private let presenter: ExpenseAIEntryPresentationLogic
    private let router: ExpenseAIEntryRoutingLogic
    private let aiParseService: MainAIParseContractServicing
    private let observer: MainFlowDomainObserverProtocol
    private let currencyCodeResolver: AddExpenseCurrencyCodeResolver
    private let draftMapper: ExpenseAIParsedDraftMapper

    private var promptText: String = ""
    private var loadingState: LoadingStatus = .idle

    init(
        presenter: ExpenseAIEntryPresentationLogic,
        router: ExpenseAIEntryRoutingLogic,
        aiParseService: MainAIParseContractServicing,
        observer: MainFlowDomainObserverProtocol,
        currencyCodeResolver: AddExpenseCurrencyCodeResolver,
        draftMapper: ExpenseAIParsedDraftMapper
    ) {
        self.presenter = presenter
        self.router = router
        self.aiParseService = aiParseService
        self.observer = observer
        self.currencyCodeResolver = currencyCodeResolver
        self.draftMapper = draftMapper
    }

    func fetchData() async {
        await presentFetchedData()
    }
}

private extension ExpenseAIEntryInteractor {
    func presentFetchedData() async {
        await presenter.presentFetchedData(
            ExpenseAIEntryFetchData(
                promptText: promptText,
                maximumCharacters: Constants.maximumCharacters,
                loadingState: loadingState,
                isPromptEditable: loadingState != .loading,
                isCloseEnabled: loadingState != .loading,
                isProcessEnabled: !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        )
    }

    func currentCurrencyCode() -> String {
        currencyCodeResolver.resolve()
    }
}

extension ExpenseAIEntryInteractor: ExpenseAIEntryHandler {
    func handleChangePrompt(_ text: String) async {
        guard loadingState != .loading else {
            return
        }

        promptText = String(text.prefix(Constants.maximumCharacters))
        await presentFetchedData()
    }

    func handleTapProcess() async {
        let trimmedPrompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard loadingState != .loading,
              !trimmedPrompt.isEmpty else {
            return
        }

        loadingState = .loading
        await router.dismissNoExpenseAlert()
        await presentFetchedData()

        do {
            let response = try await aiParseService.parse(
                .init(
                    text: trimmedPrompt,
                    currencyHint: currentCurrencyCode()
                )
            )

            loadingState = .idle

            if response.error == Constants.noExpenseDetected || response.expenses.isEmpty {
                await presentFetchedData()
                await router.presentNoExpenseAlert(output: self)
                return
            }

            let drafts = draftMapper.makeDrafts(
                from: response.expenses,
                categories: observer.currentCategoriesSnapshot().categories,
                fallbackCurrencyCode: currentCurrencyCode()
            )

            await router.openManualEntry(initialDrafts: drafts)
        } catch {
            loadingState = .idle
            await presentFetchedData()
            await router.presentError(with: L10n.mainOverviewError)
        }
    }

    func handleTapClose() async {
        guard loadingState != .loading else {
            return
        }

        await router.close()
    }

    func handleTapAddManually() async {
        guard loadingState != .loading else {
            return
        }

        await router.dismissNoExpenseAlert()
        await router.openManualEntry(
            initialDrafts: [
                .init(currencyCode: currentCurrencyCode())
            ]
        )
    }

    func handleTapFixPrompt() async {
        await router.dismissNoExpenseAlert()
        await presentFetchedData()
    }
}

extension ExpenseAIEntryInteractor: ExpenseAIEntryNoExpenseAlertOutput {}
