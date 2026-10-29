import XCTest
@testable import NetworkClient
@testable import Vylok

@MainActor
final class ExpenseAIEntryInteractorTests: XCTestCase {
    private let usage = AIParseUsageDTO(
        entriesUsed: 1,
        entriesLimit: 10,
        resetsAt: Date(timeIntervalSince1970: 1_735_725_600)
    )

    private var presenter: ExpenseAIEntryPresentationLogicMock!
    private var router: ExpenseAIEntryRoutingLogicMock!
    private var aiParseService: MainAIParseContractServicingMock!
    private var subscriptionAccessService: SubscriptionAccessServicingMock!
    private var subscriptionLimitErrorResolver: ExpenseAIEntrySubscriptionLimitErrorResolvingMock!
    private var voiceRecordingService: ExpenseAIEntryVoiceRecordingServicingMock!
    private var observer: MainFlowDomainObserverProtocolMock!
    private var userProfileStorageService: UserProfileStorageServiceProtocolMock!

    override func setUp() {
        super.setUp()
        presenter = ExpenseAIEntryPresentationLogicMock()
        router = ExpenseAIEntryRoutingLogicMock()
        aiParseService = MainAIParseContractServicingMock()
        subscriptionAccessService = SubscriptionAccessServicingMock()
        subscriptionAccessService.currentSubscriptionSnapshotReturnValue = SubscriptionAccessSnapshotFixtures.makeSnapshot(
            tier: .regular,
            capabilities: [],
            aiRequestsLimit: 0,
            aiRequestsRemaining: 0,
            statusVersion: 42,
            hasAiRequestsLimit: nil
        )
        subscriptionLimitErrorResolver = ExpenseAIEntrySubscriptionLimitErrorResolvingMock()
        subscriptionLimitErrorResolver.isSubscriptionLimitErrorReturnValue = false
        voiceRecordingService = ExpenseAIEntryVoiceRecordingServicingMock()
        voiceRecordingService.stopRecordingReturnValue = ""
        observer = MainFlowDomainObserverProtocolMock()
        observer.currentOverviewSnapshotReturnValue = .init()
        observer.currentCategoriesSnapshotReturnValue = .init()
        userProfileStorageService = UserProfileStorageServiceProtocolMock()
    }

    override func tearDown() {
        userProfileStorageService = nil
        observer = nil
        voiceRecordingService = nil
        subscriptionLimitErrorResolver = nil
        subscriptionAccessService = nil
        aiParseService = nil
        router = nil
        presenter = nil
        super.tearDown()
    }
}

extension ExpenseAIEntryInteractorTests {
    func testFetchDataBuildsEmptyPromptState() async {
        let sut = makeSUT()

        await sut.fetchData()

        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.promptText, "")
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.maximumCharacters, 280)
        XCTAssertTrue(presenter.presentFetchedDataReceivedInvocations.last?.isPromptEditable ?? false)
    }

    func testHandleChangePromptTrimsTextToMaximumCharacters() async {
        let sut = makeSUT()

        await sut.handleChangePrompt(String(repeating: "a", count: 400))

        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.promptText.count, 280)
    }
}

extension ExpenseAIEntryInteractorTests {
    func testHandleStartVoiceRecordingShowsRecordingState() async {
        let sut = makeSUT()

        await sut.handleStartVoiceRecording()

        XCTAssertEqual(voiceRecordingService.startRecordingCallsCount, 1)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.voiceRecordingState, .recording)
        XCTAssertFalse(presenter.presentFetchedDataReceivedInvocations.last?.isPromptEditable ?? true)
        XCTAssertFalse(presenter.presentFetchedDataReceivedInvocations.last?.isProcessEnabled ?? true)
    }

    func testHandleStopVoiceRecordingAppendsTranscriptAndTrimsToMaximumCharacters() async {
        voiceRecordingService.stopRecordingReturnValue = (String(repeating: "b", count: 280))
        let sut = makeSUT()

        await sut.handleChangePrompt("Coffee")
        await sut.handleStartVoiceRecording()
        await sut.handleStopVoiceRecording()

        XCTAssertEqual(voiceRecordingService.stopRecordingCallsCount, 1)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.promptText.count, 280)
        XCTAssertTrue(presenter.presentFetchedDataReceivedInvocations.last?.promptText.hasPrefix("Coffee ") ?? false)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.voiceRecordingState, .idle)
    }

    func testHandleStopVoiceRecordingKeepsPromptWhenTranscriptIsEmpty() async {
        let sut = makeSUT()

        await sut.handleChangePrompt("Coffee")
        await sut.handleStartVoiceRecording()
        await sut.handleStopVoiceRecording()

        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.promptText, "Coffee")
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.voiceRecordingState, .idle)
    }

    func testHandleStartVoiceRecordingShowsVoicePermissionPrompt() async {
        voiceRecordingService.startRecordingThrowableError = ExpenseAIEntryVoiceRecordingServiceError.microphonePermissionDenied
        let sut = makeSUT()

        await sut.handleStartVoiceRecording()

        XCTAssertEqual(router.presentVoicePermissionPromptCallsCount, 1)
        XCTAssertTrue(router.presentErrorWithReceivedInvocations.isEmpty)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.voiceRecordingState, .idle)
    }

    func testHandleStopVoiceRecordingDoesNotShowUnavailableError() async {
        voiceRecordingService.stopRecordingThrowableError = (ExpenseAIEntryVoiceRecordingServiceError.recognizerUnavailable)
        let sut = makeSUT()

        await sut.handleStartVoiceRecording()
        await sut.handleStopVoiceRecording()

        XCTAssertTrue(router.presentErrorWithReceivedInvocations.isEmpty)
        XCTAssertEqual(router.presentVoicePermissionPromptCallsCount, 0)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.voiceRecordingState, .idle)
    }

    func testHandleStopVoiceRecordingShowsPermissionPromptWhenPermissionIsDenied() async {
        voiceRecordingService.stopRecordingThrowableError = (ExpenseAIEntryVoiceRecordingServiceError.microphonePermissionDenied)
        let sut = makeSUT()

        await sut.handleStartVoiceRecording()
        await sut.handleStopVoiceRecording()

        XCTAssertEqual(router.presentVoicePermissionPromptCallsCount, 1)
        XCTAssertTrue(router.presentErrorWithReceivedInvocations.isEmpty)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.voiceRecordingState, .idle)
    }

    func testHandleTapProcessSuccessOpensManualEntryWithMappedDraft() async {
        aiParseService.parseReturnValue = .init(
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
        observer.currentCategoriesSnapshotReturnValue = .init(
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
        userProfileStorageService.loadProfileReturnValue = UserProfileDefaultsFixtures.makeProfile(
            currency: "USD",
            language: "en"
        )
        let sut = makeSUT()

        await sut.handleChangePrompt("Coffee 5")
        await sut.handleTapProcess()

        XCTAssertEqual(router.openManualEntryInitialDraftsReceivedInvocations.last?.count, 1)
        XCTAssertEqual(router.openManualEntryInitialDraftsReceivedInvocations.last?.first?.titleText, "Coffee")
        XCTAssertEqual(router.openManualEntryInitialDraftsReceivedInvocations.last?.first?.amountText, "5")
        XCTAssertEqual(router.openManualEntryInitialDraftsReceivedInvocations.last?.first?.currencyCode, "EUR")
        XCTAssertEqual(router.openManualEntryInitialDraftsReceivedInvocations.last?.first?.selectedCategory?.id, "food")
        XCTAssertEqual(userProfileStorageService.saveProfileReceivedInvocations.last?.cachedAIParseUsage, usage)
        XCTAssertEqual(subscriptionAccessService.refreshCurrentSubscriptionSnapshotCallsCount, 1)
        XCTAssertTrue(router.presentErrorWithReceivedInvocations.isEmpty)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.loadingState, .loading)
    }

    func testHandleTapProcessFailureShowsErrorToast() async {
        aiParseService.parseThrowableError = TestError.any
        let sut = makeSUT()

        await sut.handleChangePrompt("Coffee 5")
        await sut.handleTapProcess()

        XCTAssertEqual(router.presentErrorWithReceivedInvocations, [L10n.mainOverviewError])
        XCTAssertFalse(router.openManualEntryInitialDraftsCalled)
        XCTAssertEqual(subscriptionAccessService.refreshCurrentSubscriptionSnapshotCallsCount, 1)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.loadingState, .idle)
        XCTAssertTrue(presenter.presentFetchedDataReceivedInvocations.last?.isPromptEditable ?? false)
        XCTAssertTrue(presenter.presentFetchedDataReceivedInvocations.last?.isCloseEnabled ?? false)
    }

    func testHandleTapProcessFailureWithNon500StatusPersistsUsageFromRefreshedSubscription() async {
        userProfileStorageService.loadProfileReturnValue = UserProfileDefaultsFixtures.makeProfile(
            language: "en",
            cachedAIParseUsage: .init(
                entriesUsed: 2,
                entriesLimit: 300,
                resetsAt: Date(timeIntervalSince1970: 1_735_725_600)
            )
        )
        subscriptionAccessService.refreshCurrentSubscriptionSnapshotReturnValue = .init(
            tier: .premium,
            status: .active,
            paidAccessUntil: nil,
            capabilities: [.analytics, .customDateRange, .aiInput],
            aiRequestsLimit: 300,
            aiRequestsRemaining: 297,
            statusVersion: 42
        )
        aiParseService.parseThrowableError = NetworkClientError.statusCode(
            code: 400,
            NetworkClientResponseFixtures.makeResponse(statusCode: 400),
            ErrorMetadata(request: nil)
        )
        let sut = makeSUT()

        await sut.handleChangePrompt("Coffee 5")
        await sut.handleTapProcess()

        XCTAssertEqual(
            userProfileStorageService.saveProfileReceivedInvocations.last?.cachedAIParseUsage,
            .init(
                entriesUsed: 3,
                entriesLimit: 300,
                resetsAt: Date(timeIntervalSince1970: 1_735_725_600)
            )
        )
    }

    func testHandleTapProcessFailureWith500StatusDoesNotPersistUsageFromRefreshedSubscription() async {
        let initialUsage = AIParseUsageDTO(
            entriesUsed: 2,
            entriesLimit: 300,
            resetsAt: Date(timeIntervalSince1970: 1_735_725_600)
        )
        userProfileStorageService.loadProfileReturnValue = UserProfileDefaultsFixtures.makeProfile(
            language: "en",
            cachedAIParseUsage: initialUsage
        )
        subscriptionAccessService.refreshCurrentSubscriptionSnapshotReturnValue = .init(
            tier: .premium,
            status: .active,
            paidAccessUntil: nil,
            capabilities: [.analytics, .customDateRange, .aiInput],
            aiRequestsLimit: 300,
            aiRequestsRemaining: 297,
            statusVersion: 42
        )
        aiParseService.parseThrowableError = NetworkClientError.statusCode(
            code: 500,
            NetworkClientResponseFixtures.makeResponse(statusCode: 500),
            ErrorMetadata(request: nil)
        )
        let sut = makeSUT()

        await sut.handleChangePrompt("Coffee 5")
        await sut.handleTapProcess()

        XCTAssertTrue(
            userProfileStorageService.saveProfileReceivedInvocations.allSatisfy { $0.cachedAIParseUsage == initialUsage }
        )
    }

    func testHandleTapProcessSubscriptionLimitForFreeUserOpensPaywall() async {
        aiParseService.parseThrowableError = TestError.any
        subscriptionLimitErrorResolver.isSubscriptionLimitErrorReturnValue = true
        let sut = makeSUT()

        await sut.handleChangePrompt("Coffee 5")
        await sut.handleTapProcess()

        XCTAssertEqual(router.openSubscriptionCurrentTierOutputReceivedInvocations.map(\.currentTier), [.regular])
        XCTAssertTrue(router.presentErrorWithReceivedInvocations.isEmpty)
        XCTAssertFalse(router.openManualEntryInitialDraftsCalled)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.loadingState, .idle)
    }

    func testHandleTapProcessSubscriptionLimitForLegacyPaidTierShowsLimitToast() async {
        aiParseService.parseThrowableError = TestError.any
        subscriptionLimitErrorResolver.isSubscriptionLimitErrorReturnValue = true
        let premiumSnapshot = SubscriptionAccessSnapshotFixtures.makeSnapshot(
            tier: .premium,
            capabilities: [.analytics, .customDateRange, .aiInput],
            aiRequestsLimit: 300,
            aiRequestsRemaining: 300,
            statusVersion: 42,
            hasAiRequestsLimit: nil
        )
        subscriptionAccessService.currentSubscriptionSnapshotReturnValue = premiumSnapshot
        subscriptionAccessService.refreshCurrentSubscriptionSnapshotReturnValue = premiumSnapshot
        let sut = makeSUT()

        await sut.handleChangePrompt("Coffee 5")
        await sut.handleTapProcess()

        XCTAssertEqual(router.presentErrorWithReceivedInvocations, [L10n.expenseAiEntrySubscriptionLimitReached])
        XCTAssertTrue(router.openSubscriptionCurrentTierOutputReceivedInvocations.map(\.currentTier).isEmpty)
        XCTAssertFalse(router.openManualEntryInitialDraftsCalled)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.loadingState, .idle)
    }

    func testHandleTapProcessSubscriptionLimitWithExhaustedAiCreditsShowsLimitToast() async {
        aiParseService.parseThrowableError = TestError.any
        subscriptionLimitErrorResolver.isSubscriptionLimitErrorReturnValue = true
        subscriptionAccessService.currentSubscriptionSnapshotReturnValue = SubscriptionAccessSnapshotFixtures.makeSnapshot(
            tier: .premium,
            capabilities: [],
            aiRequestsLimit: 300,
            aiRequestsRemaining: 0,
            statusVersion: 42,
            hasAiRequestsLimit: nil
        )
        subscriptionAccessService.refreshCurrentSubscriptionSnapshotReturnValue = SubscriptionAccessSnapshotFixtures.makeSnapshot(
            tier: .premium,
            capabilities: [.analytics, .customDateRange, .aiInput],
            aiRequestsLimit: 300,
            aiRequestsRemaining: 300,
            statusVersion: 42,
            hasAiRequestsLimit: nil
        )
        let sut = makeSUT()

        await sut.handleChangePrompt("Coffee 5")
        await sut.handleTapProcess()

        XCTAssertEqual(router.presentErrorWithReceivedInvocations, [L10n.expenseAiEntrySubscriptionLimitReached])
        XCTAssertTrue(router.openSubscriptionCurrentTierOutputReceivedInvocations.map(\.currentTier).isEmpty)
    }

    func testHandleTapProcessNoExpenseShowsAlert() async {
        aiParseService.parseReturnValue = .init(
            expenses: [],
            usage: usage,
            error: "NO_EXPENSE_DETECTED"
        )
        let sut = makeSUT()

        await sut.handleChangePrompt("Hello")
        await sut.handleTapProcess()

        XCTAssertEqual(router.presentNoExpenseAlertOutputCallsCount, 1)
        XCTAssertTrue(presenter.presentFetchedDataReceivedInvocations.last?.isPromptEditable ?? false)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.loadingState, .idle)
    }

    func testHandleTapAddManuallyOpensEmptyDraftWithProfileCurrency() async {
        userProfileStorageService.loadProfileReturnValue = UserProfileDefaultsFixtures.makeProfile(
            currency: "KZT",
            language: "en"
        )
        let sut = makeSUT()

        await sut.handleTapAddManually()

        XCTAssertEqual(router.openManualEntryInitialDraftsReceivedInvocations.last?.count, 1)
        XCTAssertEqual(router.openManualEntryInitialDraftsReceivedInvocations.last?.first?.currencyCode, "KZT")
    }
}

private extension ExpenseAIEntryInteractorTests {
    func makeSUT() -> ExpenseAIEntryInteractor {
        ExpenseAIEntryInteractor(
            presenter: presenter,
            router: router,
            aiParseService: aiParseService,
            subscriptionAccessService: subscriptionAccessService,
            userProfileStorageService: userProfileStorageService,
            subscriptionLimitErrorResolver: subscriptionLimitErrorResolver,
            voiceRecordingService: voiceRecordingService,
            observer: observer,
            currencyCodeResolver: AddExpenseCurrencyCodeResolver(
                observer: observer,
                userProfileStorageService: userProfileStorageService
            ),
            draftMapper: ExpenseAIParsedDraftMapper()
        )
    }
}
