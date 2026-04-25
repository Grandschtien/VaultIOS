import Foundation

protocol ExpenseAIEntryBusinessLogic: Sendable {
    func fetchData() async
}

protocol ExpenseAIEntryHandler: AnyObject, Sendable {
    func handleChangePrompt(_ text: String) async
    func handleStartVoiceRecording() async
    func handleStopVoiceRecording() async
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
    private let subscriptionAccessService: SubscriptionAccessServicing
    private let subscriptionLimitErrorResolver: ExpenseAIEntrySubscriptionLimitErrorResolving
    private let voiceRecordingService: ExpenseAIEntryVoiceRecordingServicing
    private let observer: MainFlowDomainObserverProtocol
    private let currencyCodeResolver: AddExpenseCurrencyCodeResolver
    private let draftMapper: ExpenseAIParsedDraftMapper

    private var promptText: String = ""
    private var loadingState: LoadingStatus = .idle
    private var voiceRecordingState: ExpenseAIEntryVoiceRecordingState = .idle

    init(
        presenter: ExpenseAIEntryPresentationLogic,
        router: ExpenseAIEntryRoutingLogic,
        aiParseService: MainAIParseContractServicing,
        subscriptionAccessService: SubscriptionAccessServicing,
        subscriptionLimitErrorResolver: ExpenseAIEntrySubscriptionLimitErrorResolving,
        voiceRecordingService: ExpenseAIEntryVoiceRecordingServicing,
        observer: MainFlowDomainObserverProtocol,
        currencyCodeResolver: AddExpenseCurrencyCodeResolver,
        draftMapper: ExpenseAIParsedDraftMapper
    ) {
        self.presenter = presenter
        self.router = router
        self.aiParseService = aiParseService
        self.subscriptionAccessService = subscriptionAccessService
        self.subscriptionLimitErrorResolver = subscriptionLimitErrorResolver
        self.voiceRecordingService = voiceRecordingService
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
        let isVoiceRecording = voiceRecordingState == .recording

        await presenter.presentFetchedData(
            ExpenseAIEntryFetchData(
                promptText: promptText,
                maximumCharacters: Constants.maximumCharacters,
                loadingState: loadingState,
                voiceRecordingState: voiceRecordingState,
                isPromptEditable: loadingState != .loading && !isVoiceRecording,
                isCloseEnabled: loadingState != .loading && !isVoiceRecording,
                isProcessEnabled: !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && !isVoiceRecording
            )
        )
    }

    func currentCurrencyCode() -> String {
        currencyCodeResolver.resolve()
    }

    func appendTranscript(_ transcript: String) {
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscript.isEmpty else {
            return
        }

        let basePrompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        let updatedPrompt = basePrompt.isEmpty
            ? trimmedTranscript
            : "\(basePrompt) \(trimmedTranscript)"

        promptText = String(updatedPrompt.prefix(Constants.maximumCharacters))
    }

    func voiceErrorMessage(from error: Error) -> String {
        switch error as? ExpenseAIEntryVoiceRecordingServiceError {
        case .speechPermissionDenied, .microphonePermissionDenied:
            return L10n.expenseAiEntryVoicePermissionDenied
        case .recognizerUnavailable, .invalidState, nil:
            return L10n.expenseAiEntryVoiceUnavailable
        }
    }

    func handleParseError(_ error: Error) async {
        guard subscriptionLimitErrorResolver.isSubscriptionLimitError(error) else {
            await router.presentError(with: L10n.mainOverviewError)
            return
        }

        let currentTier = await subscriptionAccessService.currentTier()
        guard SubscriptionPlanResolver.hasPremiumAccess(for: currentTier) else {
            await router.openSubscription(
                currentTier: currentTier,
                output: self
            )
            return
        }

        await router.presentError(with: L10n.expenseAiEntrySubscriptionLimitReached)
    }
}

extension ExpenseAIEntryInteractor: ExpenseAIEntryHandler {
    func handleChangePrompt(_ text: String) async {
        guard loadingState != .loading,
              voiceRecordingState != .recording else {
            return
        }

        promptText = String(text.prefix(Constants.maximumCharacters))
        await presentFetchedData()
    }

    func handleStartVoiceRecording() async {
        guard loadingState != .loading,
              voiceRecordingState != .recording else {
            return
        }

        do {
            try await voiceRecordingService.startRecording()
            voiceRecordingState = .recording
            await presentFetchedData()
        } catch {
            voiceRecordingState = .idle
            await presentFetchedData()
            await router.presentError(with: voiceErrorMessage(from: error))
        }
    }

    func handleStopVoiceRecording() async {
        guard loadingState != .loading,
              voiceRecordingState == .recording else {
            return
        }

        do {
            let transcript = try await voiceRecordingService.stopRecording()
            voiceRecordingState = .idle
            appendTranscript(transcript)
            await presentFetchedData()
        } catch {
            voiceRecordingState = .idle
            await presentFetchedData()
            await router.presentError(with: voiceErrorMessage(from: error))
        }
    }

    func handleTapProcess() async {
        let trimmedPrompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard loadingState != .loading,
              voiceRecordingState != .recording,
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
            await handleParseError(error)
        }
    }

    func handleTapClose() async {
        guard loadingState != .loading,
              voiceRecordingState != .recording else {
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

extension ExpenseAIEntryInteractor: SubscriptionOutput {
    func handleSubscriptionDidSync() async {
        _ = await subscriptionAccessService.refreshCurrentTier()
    }
}
