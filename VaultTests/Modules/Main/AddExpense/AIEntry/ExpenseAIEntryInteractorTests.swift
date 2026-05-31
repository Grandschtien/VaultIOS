import XCTest
@testable import Vault

@MainActor
final class ExpenseAIEntryInteractorTests: XCTestCase {
    func testFetchDataBuildsEmptyPromptState() async {
        let presenter = ExpenseAIEntryPresenterSpy()
        let sut = makeSUT(presenter: presenter)

        await sut.fetchData()

        XCTAssertEqual(presenter.presentedData.last?.promptText, "")
        XCTAssertEqual(presenter.presentedData.last?.maximumCharacters, 280)
        XCTAssertTrue(presenter.presentedData.last?.isPromptEditable ?? false)
    }

    func testHandleChangePromptTrimsTextToMaximumCharacters() async {
        let presenter = ExpenseAIEntryPresenterSpy()
        let sut = makeSUT(presenter: presenter)

        await sut.handleChangePrompt(String(repeating: "a", count: 400))

        XCTAssertEqual(presenter.presentedData.last?.promptText.count, 280)
    }
}

extension ExpenseAIEntryInteractorTests {
    func testHandleStartVoiceRecordingShowsRecordingState() async {
        let presenter = ExpenseAIEntryPresenterSpy()
        let voiceService = VoiceRecordingServiceSpy()
        let sut = makeSUT(
            presenter: presenter,
            voiceRecordingService: voiceService
        )

        await sut.handleStartVoiceRecording()

        XCTAssertEqual(voiceService.startCallsCount, 1)
        XCTAssertEqual(presenter.presentedData.last?.voiceRecordingState, .recording)
        XCTAssertFalse(presenter.presentedData.last?.isPromptEditable ?? true)
        XCTAssertFalse(presenter.presentedData.last?.isProcessEnabled ?? true)
    }

    func testHandleStopVoiceRecordingAppendsTranscriptAndTrimsToMaximumCharacters() async {
        let presenter = ExpenseAIEntryPresenterSpy()
        let voiceService = VoiceRecordingServiceSpy()
        voiceService.stopResult = .success(String(repeating: "b", count: 280))
        let sut = makeSUT(
            presenter: presenter,
            voiceRecordingService: voiceService
        )

        await sut.handleChangePrompt("Coffee")
        await sut.handleStartVoiceRecording()
        await sut.handleStopVoiceRecording()

        XCTAssertEqual(voiceService.stopCallsCount, 1)
        XCTAssertEqual(presenter.presentedData.last?.promptText.count, 280)
        XCTAssertTrue(presenter.presentedData.last?.promptText.hasPrefix("Coffee ") ?? false)
        XCTAssertEqual(presenter.presentedData.last?.voiceRecordingState, .idle)
    }

    func testHandleStopVoiceRecordingKeepsPromptWhenTranscriptIsEmpty() async {
        let presenter = ExpenseAIEntryPresenterSpy()
        let voiceService = VoiceRecordingServiceSpy()
        let sut = makeSUT(
            presenter: presenter,
            voiceRecordingService: voiceService
        )

        await sut.handleChangePrompt("Coffee")
        await sut.handleStartVoiceRecording()
        await sut.handleStopVoiceRecording()

        XCTAssertEqual(presenter.presentedData.last?.promptText, "Coffee")
        XCTAssertEqual(presenter.presentedData.last?.voiceRecordingState, .idle)
    }

    func testHandleStartVoiceRecordingShowsVoicePermissionPrompt() async {
        let presenter = ExpenseAIEntryPresenterSpy()
        let router = ExpenseAIEntryRouterSpy()
        let voiceService = VoiceRecordingServiceSpy()
        voiceService.startError = ExpenseAIEntryVoiceRecordingServiceError.microphonePermissionDenied
        let sut = makeSUT(
            presenter: presenter,
            router: router,
            voiceRecordingService: voiceService
        )

        await sut.handleStartVoiceRecording()

        XCTAssertEqual(router.voicePermissionPromptPresentationsCount, 1)
        XCTAssertTrue(router.presentedErrors.isEmpty)
        XCTAssertEqual(presenter.presentedData.last?.voiceRecordingState, .idle)
    }

    func testHandleStopVoiceRecordingDoesNotShowUnavailableError() async {
        let presenter = ExpenseAIEntryPresenterSpy()
        let router = ExpenseAIEntryRouterSpy()
        let voiceService = VoiceRecordingServiceSpy()
        voiceService.stopResult = .failure(ExpenseAIEntryVoiceRecordingServiceError.recognizerUnavailable)
        let sut = makeSUT(
            presenter: presenter,
            router: router,
            voiceRecordingService: voiceService
        )

        await sut.handleStartVoiceRecording()
        await sut.handleStopVoiceRecording()

        XCTAssertTrue(router.presentedErrors.isEmpty)
        XCTAssertEqual(router.voicePermissionPromptPresentationsCount, 0)
        XCTAssertEqual(presenter.presentedData.last?.voiceRecordingState, .idle)
    }

    func testHandleStopVoiceRecordingShowsPermissionPromptWhenPermissionIsDenied() async {
        let presenter = ExpenseAIEntryPresenterSpy()
        let router = ExpenseAIEntryRouterSpy()
        let voiceService = VoiceRecordingServiceSpy()
        voiceService.stopResult = .failure(ExpenseAIEntryVoiceRecordingServiceError.microphonePermissionDenied)
        let sut = makeSUT(
            presenter: presenter,
            router: router,
            voiceRecordingService: voiceService
        )

        await sut.handleStartVoiceRecording()
        await sut.handleStopVoiceRecording()

        XCTAssertEqual(router.voicePermissionPromptPresentationsCount, 1)
        XCTAssertTrue(router.presentedErrors.isEmpty)
        XCTAssertEqual(presenter.presentedData.last?.voiceRecordingState, .idle)
    }

    func testHandleTapProcessSuccessOpensManualEntryWithMappedDraft() async {
        let presenter = ExpenseAIEntryPresenterSpy()
        let router = ExpenseAIEntryRouterSpy()
        let subscriptionAccessService = SubscriptionAccessServiceStub()
        let service = AIParseServiceSpy(
            result: .success(
                .init(
                    expenses: [
                        .init(
                            title: "Coffee",
                            amount: 5,
                            currency: "EUR",
                            category: "UNMAPPED",
                            suggestedCategory: "Food",
                            confidence: 0.92
                        )
                    ],
                    usage: usage,
                    error: nil
                )
            )
        )
        let observer = MainFlowObserverStub(
            categoriesSnapshot: .init(
                categories: [
                    .init(
                        id: "food",
                        name: "Food",
                        icon: "🍔",
                        color: "green",
                        amount: 0,
                        currency: "USD"
                    )
                ]
            )
        )
        let sut = makeSUT(
            presenter: presenter,
            router: router,
            aiParseService: service,
            subscriptionAccessService: subscriptionAccessService,
            observer: observer
        )

        await sut.handleChangePrompt("Coffee 5")
        await sut.handleTapProcess()

        let refreshCallsCount = await subscriptionAccessService.refreshCurrentSubscriptionSnapshotCallsCount()

        XCTAssertEqual(router.openedDrafts?.count, 1)
        XCTAssertEqual(router.openedDrafts?.first?.titleText, "Coffee")
        XCTAssertEqual(router.openedDrafts?.first?.amountText, "5")
        XCTAssertEqual(router.openedDrafts?.first?.currencyCode, "EUR")
        XCTAssertEqual(router.openedDrafts?.first?.selectedCategory?.id, "food")
        XCTAssertEqual(refreshCallsCount, 1)
        XCTAssertTrue(router.presentedErrors.isEmpty)
        XCTAssertEqual(presenter.presentedData.last?.loadingState, .loading)
    }

    func testHandleTapProcessFailureShowsErrorToast() async {
        let presenter = ExpenseAIEntryPresenterSpy()
        let router = ExpenseAIEntryRouterSpy()
        let subscriptionAccessService = SubscriptionAccessServiceStub()
        let service = AIParseServiceSpy(result: .failure(ExpenseAIEntryTestError.any))
        let sut = makeSUT(
            presenter: presenter,
            router: router,
            aiParseService: service,
            subscriptionAccessService: subscriptionAccessService
        )

        await sut.handleChangePrompt("Coffee 5")
        await sut.handleTapProcess()

        let refreshCallsCount = await subscriptionAccessService.refreshCurrentSubscriptionSnapshotCallsCount()

        XCTAssertEqual(router.presentedErrors, [L10n.mainOverviewError])
        XCTAssertNil(router.openedDrafts)
        XCTAssertEqual(refreshCallsCount, 1)
        XCTAssertEqual(presenter.presentedData.last?.loadingState, .idle)
        XCTAssertTrue(presenter.presentedData.last?.isPromptEditable ?? false)
        XCTAssertTrue(presenter.presentedData.last?.isCloseEnabled ?? false)
    }

    func testHandleTapProcessSubscriptionLimitForFreeUserOpensPaywall() async {
        let presenter = ExpenseAIEntryPresenterSpy()
        let router = ExpenseAIEntryRouterSpy()
        let service = AIParseServiceSpy(result: .failure(ExpenseAIEntryTestError.any))
        let sut = makeSUT(
            presenter: presenter,
            router: router,
            aiParseService: service,
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "REGULAR"),
            subscriptionLimitErrorResolver: ExpenseAIEntrySubscriptionLimitErrorResolverStub(
                isSubscriptionLimitError: true
            )
        )

        await sut.handleChangePrompt("Coffee 5")
        await sut.handleTapProcess()

        XCTAssertEqual(router.openedSubscriptionTiers, [.regular])
        XCTAssertTrue(router.presentedErrors.isEmpty)
        XCTAssertNil(router.openedDrafts)
        XCTAssertEqual(presenter.presentedData.last?.loadingState, .idle)
    }

    func testHandleTapProcessSubscriptionLimitForLegacyPaidTierShowsLimitToast() async {
        let presenter = ExpenseAIEntryPresenterSpy()
        let router = ExpenseAIEntryRouterSpy()
        let service = AIParseServiceSpy(result: .failure(ExpenseAIEntryTestError.any))
        let sut = makeSUT(
            presenter: presenter,
            router: router,
            aiParseService: service,
            subscriptionAccessService: SubscriptionAccessServiceStub(currentTier: "PLUS"),
            subscriptionLimitErrorResolver: ExpenseAIEntrySubscriptionLimitErrorResolverStub(
                isSubscriptionLimitError: true
            )
        )

        await sut.handleChangePrompt("Coffee 5")
        await sut.handleTapProcess()

        XCTAssertEqual(router.presentedErrors, [L10n.expenseAiEntrySubscriptionLimitReached])
        XCTAssertTrue(router.openedSubscriptionTiers.isEmpty)
        XCTAssertNil(router.openedDrafts)
        XCTAssertEqual(presenter.presentedData.last?.loadingState, .idle)
    }

    func testHandleTapProcessSubscriptionLimitWithExhaustedAiCreditsShowsLimitToast() async {
        let presenter = ExpenseAIEntryPresenterSpy()
        let router = ExpenseAIEntryRouterSpy()
        let service = AIParseServiceSpy(result: .failure(ExpenseAIEntryTestError.any))
        let sut = makeSUT(
            presenter: presenter,
            router: router,
            aiParseService: service,
            subscriptionAccessService: SubscriptionAccessServiceStub(
                currentTier: "PREMIUM",
                currentSnapshot: .init(
                    tier: .premium,
                    status: .active,
                    paidAccessUntil: nil,
                    capabilities: [],
                    aiRequestsLimit: 300,
                    aiRequestsRemaining: 0,
                    statusVersion: 42
                )
            ),
            subscriptionLimitErrorResolver: ExpenseAIEntrySubscriptionLimitErrorResolverStub(
                isSubscriptionLimitError: true
            )
        )

        await sut.handleChangePrompt("Coffee 5")
        await sut.handleTapProcess()

        XCTAssertEqual(router.presentedErrors, [L10n.expenseAiEntrySubscriptionLimitReached])
        XCTAssertTrue(router.openedSubscriptionTiers.isEmpty)
    }

    func testHandleTapProcessNoExpenseShowsAlert() async {
        let presenter = ExpenseAIEntryPresenterSpy()
        let router = ExpenseAIEntryRouterSpy()
        let service = AIParseServiceSpy(
            result: .success(
                .init(
                    expenses: [],
                    usage: usage,
                    error: "NO_EXPENSE_DETECTED"
                )
            )
        )
        let sut = makeSUT(
            presenter: presenter,
            router: router,
            aiParseService: service
        )

        await sut.handleChangePrompt("Hello")
        await sut.handleTapProcess()

        XCTAssertEqual(router.noExpenseAlertPresentationsCount, 1)
        XCTAssertTrue(presenter.presentedData.last?.isPromptEditable ?? false)
        XCTAssertEqual(presenter.presentedData.last?.loadingState, .idle)
    }

    func testHandleTapAddManuallyOpensEmptyDraftWithProfileCurrency() async {
        let router = ExpenseAIEntryRouterSpy()
        let sut = makeSUT(
            router: router,
            userProfileStorageService: UserProfileStorageSpy(
                profile: .init(
                    userId: "1",
                    email: "test@example.com",
                    name: "Test",
                    currency: "KZT",
                    language: "en"
                )
            )
        )

        await sut.handleTapAddManually()

        XCTAssertEqual(router.openedDrafts?.count, 1)
        XCTAssertEqual(router.openedDrafts?.first?.currencyCode, "KZT")
    }
}

@MainActor
private extension ExpenseAIEntryInteractorTests {
    var usage: AIParseUsageDTO {
        .init(
            entriesUsed: 1,
            entriesLimit: 10,
            resetsAt: Date(timeIntervalSince1970: 1_735_725_600)
        )
    }

    func makeSUT(
        presenter: ExpenseAIEntryPresenterSpy? = nil,
        router: ExpenseAIEntryRouterSpy? = nil,
        aiParseService: AIParseServiceSpy? = nil,
        subscriptionAccessService: SubscriptionAccessServicing = SubscriptionAccessServiceStub(),
        subscriptionLimitErrorResolver: ExpenseAIEntrySubscriptionLimitErrorResolving = ExpenseAIEntrySubscriptionLimitErrorResolverStub(),
        voiceRecordingService: VoiceRecordingServiceSpy? = nil,
        observer: MainFlowObserverStub = .init(),
        userProfileStorageService: UserProfileStorageSpy = .init()
    ) -> ExpenseAIEntryInteractor {
        let resolvedPresenter = presenter ?? ExpenseAIEntryPresenterSpy()
        let resolvedRouter = router ?? ExpenseAIEntryRouterSpy()
        let resolvedAIParseService = aiParseService ?? AIParseServiceSpy(
            result: .success(
                .init(
                    expenses: [],
                    usage: usage,
                    error: nil
                )
            )
        )
        let resolvedVoiceRecordingService = voiceRecordingService ?? VoiceRecordingServiceSpy()

        return ExpenseAIEntryInteractor(
            presenter: resolvedPresenter,
            router: resolvedRouter,
            aiParseService: resolvedAIParseService,
            subscriptionAccessService: subscriptionAccessService,
            subscriptionLimitErrorResolver: subscriptionLimitErrorResolver,
            voiceRecordingService: resolvedVoiceRecordingService,
            observer: observer,
            currencyCodeResolver: AddExpenseCurrencyCodeResolver(
                observer: observer,
                userProfileStorageService: userProfileStorageService
            ),
            draftMapper: ExpenseAIParsedDraftMapper()
        )
    }
}

@MainActor
private final class ExpenseAIEntryPresenterSpy: ExpenseAIEntryPresentationLogic {
    private(set) var presentedData: [ExpenseAIEntryFetchData] = []

    func presentFetchedData(_ data: ExpenseAIEntryFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class ExpenseAIEntryRouterSpy: ExpenseAIEntryRoutingLogic {
    private(set) var closeCallsCount = 0
    private(set) var presentedErrors: [String] = []
    private(set) var voicePermissionPromptPresentationsCount = 0
    private(set) var openedDrafts: [ExpenseEditableDraft]?
    private(set) var openedSubscriptionTiers: [SubscriptionTier] = []
    private(set) var noExpenseAlertPresentationsCount = 0
    private(set) var dismissNoExpenseAlertCallsCount = 0

    func close() {
        closeCallsCount += 1
    }

    func presentError(with text: String) {
        presentedErrors.append(text)
    }

    func presentVoicePermissionPrompt() {
        voicePermissionPromptPresentationsCount += 1
    }

    func presentNoExpenseAlert(output: ExpenseAIEntryNoExpenseAlertOutput) {
        noExpenseAlertPresentationsCount += 1
    }

    func dismissNoExpenseAlert() {
        dismissNoExpenseAlertCallsCount += 1
    }

    func openSubscription(
        currentTier: SubscriptionTier,
        output: SubscriptionOutput
    ) {
        openedSubscriptionTiers.append(currentTier)
    }

    func openManualEntry(initialDrafts: [ExpenseEditableDraft]) async {
        openedDrafts = initialDrafts
    }
}

private struct ExpenseAIEntrySubscriptionLimitErrorResolverStub: ExpenseAIEntrySubscriptionLimitErrorResolving {
    let shouldResolveAsSubscriptionLimitError: Bool

    init(isSubscriptionLimitError: Bool = false) {
        shouldResolveAsSubscriptionLimitError = isSubscriptionLimitError
    }

    func isSubscriptionLimitError(_ error: Error) -> Bool {
        shouldResolveAsSubscriptionLimitError
    }
}

private actor SubscriptionAccessServiceStub: SubscriptionAccessServicing {
    private let currentSnapshot: SubscriptionAccessSnapshot
    private let refreshedSnapshot: SubscriptionAccessSnapshot
    private var refreshCurrentSubscriptionSnapshotCallsCountValue = 0

    init(
        currentTier: String = "REGULAR",
        refreshedTier: String? = nil,
        currentSnapshot: SubscriptionAccessSnapshot? = nil,
        refreshedSnapshot: SubscriptionAccessSnapshot? = nil
    ) {
        self.currentSnapshot = currentSnapshot ?? Self.makeSnapshot(tier: currentTier)
        self.refreshedSnapshot = refreshedSnapshot ?? Self.makeSnapshot(tier: refreshedTier ?? currentTier)
    }

    func currentTierState() async -> SubscriptionTierState {
        .resolved(currentSnapshot.tier)
    }

    func refreshCurrentTierState() async -> SubscriptionTierState {
        .resolved(refreshedSnapshot.tier)
    }

    func refreshCurrentTierSourceState() async -> SubscriptionTierRefreshState {
        .network(refreshedSnapshot.tier)
    }

    func currentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot? {
        currentSnapshot
    }

    func refreshCurrentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot? {
        refreshCurrentSubscriptionSnapshotCallsCountValue += 1
        refreshedSnapshot
    }

    func refreshCurrentSubscriptionSnapshotCallsCount() async -> Int {
        refreshCurrentSubscriptionSnapshotCallsCountValue
    }

    nonisolated private static func makeSnapshot(tier: String) -> SubscriptionAccessSnapshot {
        let capabilities: [SubscriptionCapability] = switch tier {
        case "PREMIUM", "PLUS", "ACTIVE":
            [
                SubscriptionCapability.analytics,
                .customDateRange,
                .aiInput
            ]
        default:
            []
        }

        return SubscriptionAccessSnapshot(
            tier: tier == "REGULAR" ? .regular : .premium,
            status: .active,
            paidAccessUntil: nil,
            capabilities: capabilities,
            aiRequestsLimit: capabilities.isEmpty ? 0 : 300,
            aiRequestsRemaining: capabilities.isEmpty ? 0 : 300,
            statusVersion: 42
        )
    }
}

private actor AIParseServiceSpy: MainAIParseContractServicing {
    private let result: Result<AIParseResponseDTO, Error>

    init(result: Result<AIParseResponseDTO, Error>) {
        self.result = result
    }

    func parse(_ request: AIParseRequestDTO) async throws -> AIParseResponseDTO {
        try result.get()
    }
}

@MainActor
private final class VoiceRecordingServiceSpy: ExpenseAIEntryVoiceRecordingServicing {
    private(set) var startCallsCount = 0
    private(set) var stopCallsCount = 0
    var startError: Error?
    var stopResult: Result<String, Error> = .success("")

    func startRecording() async throws {
        startCallsCount += 1

        if let startError {
            throw startError
        }
    }

    func stopRecording() async throws -> String {
        stopCallsCount += 1
        return try stopResult.get()
    }
}

private final class MainFlowObserverStub: MainFlowDomainObserverProtocol, @unchecked Sendable {
    private let overviewSnapshot: MainFlowOverviewSnapshot
    private let categoriesSnapshot: MainFlowCategoriesSnapshot

    init(
        overviewSnapshot: MainFlowOverviewSnapshot = .init(),
        categoriesSnapshot: MainFlowCategoriesSnapshot = .init()
    ) {
        self.overviewSnapshot = overviewSnapshot
        self.categoriesSnapshot = categoriesSnapshot
    }

    func subscribeOverview() -> AsyncStream<MainFlowOverviewSnapshot> {
        AsyncStream { $0.finish() }
    }

    func subscribeCategories() -> AsyncStream<MainFlowCategoriesSnapshot> {
        AsyncStream { $0.finish() }
    }

    func subscribeCategory(id: String) -> AsyncStream<MainFlowCategorySnapshot> {
        AsyncStream { $0.finish() }
    }

    func subscribeExpensesList() -> AsyncStream<MainFlowExpensesListSnapshot> {
        AsyncStream { $0.finish() }
    }

    func currentOverviewSnapshot() -> MainFlowOverviewSnapshot {
        overviewSnapshot
    }

    func currentCategoriesSnapshot() -> MainFlowCategoriesSnapshot {
        categoriesSnapshot
    }

    func currentCategorySnapshot(id: String) -> MainFlowCategorySnapshot {
        .init(categoryID: id)
    }

    func currentExpensesListSnapshot() -> MainFlowExpensesListSnapshot {
        .init()
    }

    func publishAll(from store: MainFlowDomainStoreProtocol) {}

    func finishAll() {}
}

private enum ExpenseAIEntryTestError: Error {
    case any
}

private final class UserProfileStorageSpy: UserProfileStorageServiceProtocol, @unchecked Sendable {
    private var profile: UserProfileDefaults?

    init(profile: UserProfileDefaults? = nil) {
        self.profile = profile
    }

    func saveProfile(_ profile: UserProfileDefaults) {
        self.profile = profile
    }

    func loadProfile() -> UserProfileDefaults? {
        profile
    }

    func clearProfile() {
        profile = nil
    }
}
