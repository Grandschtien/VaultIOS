import XCTest
@testable import Vylok

final class CategoryEditorInteractorTests: XCTestCase {
    private var presenter: CategoryEditorPresentationLogicMock!
    private var router: CategoryEditorRoutingLogicMock!
    private var repository: MainFlowDomainRepositoryProtocolMock!
    private var observer: MainFlowDomainObserverProtocolMock!
    private var subscriptionAccessService: SubscriptionAccessServicingMock!
    private var subscriptionLimitErrorResolver: CategoryEditorSubscriptionLimitErrorResolvingMock!
    private var presetProvider: CategoryEditorPresetProvidingMock!
    private var colorProvider: CategoryColorProvidingMock!
    private var analytics: CategoryEditorAnalyticsTrackingMock!
    private var sut: CategoryEditorInteractor!

    override func setUp() {
        super.setUp()
        presenter = CategoryEditorPresentationLogicMock()
        router = CategoryEditorRoutingLogicMock()
        repository = MainFlowDomainRepositoryProtocolMock()
        observer = MainFlowDomainObserverProtocolMock()
        subscriptionAccessService = SubscriptionAccessServicingMock()
        subscriptionLimitErrorResolver = CategoryEditorSubscriptionLimitErrorResolvingMock()
        presetProvider = CategoryEditorPresetProvidingMock()
        colorProvider = CategoryColorProvidingMock()
        analytics = CategoryEditorAnalyticsTrackingMock()
        presetProvider.defaultEmoji = "😀"
        presetProvider.defaultColorHex = "#FFFFFF"
        sut = CategoryEditorInteractor(
            mode: .create,
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            subscriptionAccessService: subscriptionAccessService,
            subscriptionLimitErrorResolver: subscriptionLimitErrorResolver,
            presetProvider: presetProvider,
            colorProvider: colorProvider,
            analytics: analytics
        )
    }

    override func tearDown() {
        sut = nil
        analytics = nil
        colorProvider = nil
        presetProvider = nil
        subscriptionLimitErrorResolver = nil
        subscriptionAccessService = nil
        observer = nil
        repository = nil
        router = nil
        presenter = nil
        super.tearDown()
    }
}

// MARK: - fetchData

extension CategoryEditorInteractorTests {
    func testFetchDataInCreateModePresentsDefaultDraftAndTracksScreenOpen() async {
        // Act
        await sut.fetchData()

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [CategoryEditorFetchData(mode: .create, loadingState: .loaded, draft: Self.defaultDraft)]
        )
        XCTAssertEqual(analytics.trackScreenOpenCallsCount, 1)
    }

    func testFetchDataInEditModePrefillsCategoryWithCustomEmojiAndColor() async {
        // Arrange
        let sut = makeEditSut()
        observer.currentCategorySnapshotIdReturnValue = MainFlowCategorySnapshot(
            categoryID: "food",
            category: Self.foodCategory
        )
        observer.currentCategoriesSnapshotReturnValue = MainFlowCategoriesSnapshot()
        colorProvider.normalizedHexFromClosure = { $0 }
        presetProvider.emojiPresetsReturnValue = ["😀", "🍔"]
        presetProvider.colorPresetsReturnValue = ["#FFFFFF", "#A0E7E5"]

        // Act
        await sut.fetchData()

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                CategoryEditorFetchData(
                    mode: .edit(id: "food"),
                    loadingState: .loading,
                    draft: Self.defaultDraft,
                    isDeleteVisible: true
                ),
                CategoryEditorFetchData(
                    mode: .edit(id: "food"),
                    loadingState: .loaded,
                    draft: Self.foodDraft,
                    prefilledCustomEmoji: "🍕",
                    prefilledCustomColorHex: "#123456",
                    isDeleteVisible: true
                )
            ]
        )
        XCTAssertFalse(repository.refreshCategoriesCalled)
    }

    func testFetchDataInEditModeWhenCategoryIsMissingRefreshesAndPresentsFailure() async {
        // Arrange
        let sut = makeEditSut()
        observer.currentCategorySnapshotIdReturnValue = MainFlowCategorySnapshot(
            categoryID: "food",
            category: nil
        )
        observer.currentCategoriesSnapshotReturnValue = MainFlowCategoriesSnapshot()
        colorProvider.normalizedHexFromClosure = { $0 }
        presetProvider.emojiPresetsReturnValue = ["😀", "🍔"]
        presetProvider.colorPresetsReturnValue = ["#FFFFFF", "#A0E7E5"]

        // Act
        await sut.fetchData()

        // Assert
        XCTAssertEqual(repository.refreshCategoriesCallsCount, 1)
        XCTAssertEqual(repository.refreshCategoryFirstPageIdFromDateToDateReceivedArguments?.id, "food")
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations.last,
            CategoryEditorFetchData(
                mode: .edit(id: "food"),
                loadingState: .failed(.undelinedError(description: L10n.mainOverviewError)),
                draft: Self.defaultDraft,
                isDeleteVisible: true
            )
        )
    }

    func testFetchDataInEditModeWhenCategoryIsUnmappedHidesDelete() async {
        // Arrange
        let sut = makeEditSut()
        observer.currentCategorySnapshotIdReturnValue = MainFlowCategorySnapshot(
            categoryID: "food",
            category: MainCategoryCardModel(
                id: "food",
                name: "Unmapped",
                icon: "😀",
                color: "#FFFFFF",
                amount: 12,
                currency: "USD"
            )
        )
        observer.currentCategoriesSnapshotReturnValue = MainFlowCategoriesSnapshot()
        colorProvider.normalizedHexFromClosure = { $0 }
        presetProvider.emojiPresetsReturnValue = ["😀", "🍔"]
        presetProvider.colorPresetsReturnValue = ["#FFFFFF", "#A0E7E5"]

        // Act
        await sut.fetchData()

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations.last,
            CategoryEditorFetchData(
                mode: .edit(id: "food"),
                loadingState: .loaded,
                draft: CategoryEditorDraft(name: "Unmapped", emoji: "😀", colorHex: "#FFFFFF")
            )
        )
    }
}

// MARK: - handleTapPrimaryButton

extension CategoryEditorInteractorTests {
    func testHandleTapPrimaryButtonWhenNameIsEmptyShowsNameError() async {
        // Arrange
        await sut.fetchData()

        // Act
        await sut.handleTapPrimaryButton()

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations.last,
            CategoryEditorFetchData(
                mode: .create,
                loadingState: .loaded,
                draft: Self.defaultDraft,
                shouldShowNameError: true
            )
        )
        XCTAssertFalse(repository.addCategoryCalled)
    }

    func testHandleTapPrimaryButtonInCreateModeAddsTrimmedCategoryAndCloses() async {
        // Arrange
        repository.addCategoryReturnValue = Self.foodCategory
        await sut.fetchData()
        await sut.handleChangeCategoryName("  Travel ")

        // Act
        await sut.handleTapPrimaryButton()

        // Assert
        XCTAssertEqual(
            repository.addCategoryReceivedInvocations,
            [CategoryCreateRequestDTO(name: "Travel", icon: "😀", color: "#FFFFFF")]
        )
        XCTAssertEqual(router.closeCallsCount, 1)
    }

    func testHandleTapPrimaryButtonInCreateModeWhenLimitIsReachedOpensPaywall() async throws {
        // Arrange
        repository.addCategoryThrowableError = TestError.any
        subscriptionLimitErrorResolver.isSubscriptionLimitErrorReturnValue = true
        subscriptionAccessService.currentTierStateReturnValue = .resolved(.regular)
        await sut.fetchData()
        await sut.handleChangeCategoryName("Travel")

        // Act
        await sut.handleTapPrimaryButton()

        // Assert
        let arguments = try XCTUnwrap(router.openSubscriptionCurrentTierOutputReceivedArguments)
        XCTAssertEqual(arguments.currentTier, .regular)
        XCTAssertTrue(arguments.output === sut)
        XCTAssertEqual(analytics.trackPaywallOpenCurrentTierReceivedInvocations, ["REGULAR"])
        XCTAssertFalse(router.presentErrorWithCalled)
    }

    func testHandleTapPrimaryButtonInCreateModeWhenRequestFailsPresentsError() async {
        // Arrange
        repository.addCategoryThrowableError = TestError.any
        subscriptionLimitErrorResolver.isSubscriptionLimitErrorReturnValue = false
        await sut.fetchData()
        await sut.handleChangeCategoryName("Travel")

        // Act
        await sut.handleTapPrimaryButton()

        // Assert
        XCTAssertEqual(router.presentErrorWithReceivedInvocations, [L10n.mainOverviewError])
        XCTAssertFalse(router.closeCalled)
    }

    func testHandleTapPrimaryButtonInEditModeUpdatesCategoryAndCloses() async throws {
        // Arrange
        let sut = makeEditSut()
        observer.currentCategorySnapshotIdReturnValue = MainFlowCategorySnapshot(
            categoryID: "food",
            category: Self.foodCategory
        )
        observer.currentCategoriesSnapshotReturnValue = MainFlowCategoriesSnapshot()
        colorProvider.normalizedHexFromClosure = { $0 }
        presetProvider.emojiPresetsReturnValue = ["😀", "🍔"]
        presetProvider.colorPresetsReturnValue = ["#FFFFFF", "#A0E7E5"]
        repository.updateCategoryIdRequestReturnValue = Self.foodCategory
        await sut.fetchData()
        await sut.handleChangeCategoryName("Groceries")

        // Act
        await sut.handleTapPrimaryButton()

        // Assert
        let arguments = try XCTUnwrap(repository.updateCategoryIdRequestReceivedArguments)
        XCTAssertTrue(
            arguments == (id: "food", request: CategoryCreateRequestDTO(name: "Groceries", icon: "🍕", color: "#123456"))
        )
        XCTAssertEqual(router.closeCallsCount, 1)
    }

    func testHandleTapPrimaryButtonInEditModeWhenRequestFailsPresentsError() async {
        // Arrange
        let sut = makeEditSut()
        observer.currentCategorySnapshotIdReturnValue = MainFlowCategorySnapshot(
            categoryID: "food",
            category: Self.foodCategory
        )
        observer.currentCategoriesSnapshotReturnValue = MainFlowCategoriesSnapshot()
        colorProvider.normalizedHexFromClosure = { $0 }
        presetProvider.emojiPresetsReturnValue = ["😀", "🍔"]
        presetProvider.colorPresetsReturnValue = ["#FFFFFF", "#A0E7E5"]
        repository.updateCategoryIdRequestThrowableError = TestError.any
        await sut.fetchData()
        await sut.handleChangeCategoryName("Groceries")

        // Act
        await sut.handleTapPrimaryButton()

        // Assert
        XCTAssertEqual(router.presentErrorWithReceivedInvocations, [L10n.mainOverviewError])
        XCTAssertFalse(subscriptionLimitErrorResolver.isSubscriptionLimitErrorCalled)
    }
}

// MARK: - handleChangeCategoryName

extension CategoryEditorInteractorTests {
    func testHandleChangeCategoryNameInEditModeEnablesPrimaryWhenDraftChanges() async {
        // Arrange
        let sut = makeEditSut()
        observer.currentCategorySnapshotIdReturnValue = MainFlowCategorySnapshot(
            categoryID: "food",
            category: Self.foodCategory
        )
        observer.currentCategoriesSnapshotReturnValue = MainFlowCategoriesSnapshot()
        colorProvider.normalizedHexFromClosure = { $0 }
        presetProvider.emojiPresetsReturnValue = ["😀", "🍔"]
        presetProvider.colorPresetsReturnValue = ["#FFFFFF", "#A0E7E5"]
        await sut.fetchData()

        // Act
        await sut.handleChangeCategoryName("Groceries")

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations.last,
            CategoryEditorFetchData(
                mode: .edit(id: "food"),
                loadingState: .loaded,
                draft: CategoryEditorDraft(name: "Groceries", emoji: "🍕", colorHex: "#123456"),
                prefilledCustomEmoji: "🍕",
                prefilledCustomColorHex: "#123456",
                isPrimaryEnabled: true,
                isDeleteVisible: true
            )
        )
    }
}

// MARK: - handleTapEmojiPreset

extension CategoryEditorInteractorTests {
    func testHandleTapEmojiPresetUpdatesDraftEmoji() async {
        // Arrange
        await sut.fetchData()

        // Act
        await sut.handleTapEmojiPreset("🍔")

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations.last,
            CategoryEditorFetchData(
                mode: .create,
                loadingState: .loaded,
                draft: CategoryEditorDraft(name: "", emoji: "🍔", colorHex: "#FFFFFF")
            )
        )
    }
}

// MARK: - handleTapCustomEmojiButton

extension CategoryEditorInteractorTests {
    func testHandleTapCustomEmojiButtonRequestsEmojiKeyboardFocus() async throws {
        // Arrange
        await sut.fetchData()

        // Act
        await sut.handleTapCustomEmojiButton()

        // Assert
        let presented = try XCTUnwrap(presenter.presentFetchedDataReceivedInvocations.last)
        let focusID = try XCTUnwrap(presented.customEmojiFocusID)
        XCTAssertEqual(
            presented,
            CategoryEditorFetchData(
                mode: .create,
                loadingState: .loaded,
                draft: Self.defaultDraft,
                customEmojiFocusID: focusID
            )
        )
    }
}

// MARK: - handleDidSelectEmoji

extension CategoryEditorInteractorTests {
    func testHandleDidSelectEmojiUpdatesDraftAndClearsFocus() async {
        // Arrange
        await sut.fetchData()
        await sut.handleTapCustomEmojiButton()

        // Act
        await sut.handleDidSelectEmoji("🚀")

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations.last,
            CategoryEditorFetchData(
                mode: .create,
                loadingState: .loaded,
                draft: CategoryEditorDraft(name: "", emoji: "🚀", colorHex: "#FFFFFF")
            )
        )
    }
}

// MARK: - handleTapColorPreset

extension CategoryEditorInteractorTests {
    func testHandleTapColorPresetUpdatesDraftColor() async {
        // Arrange
        await sut.fetchData()

        // Act
        await sut.handleTapColorPreset("#A0E7E5")

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations.last,
            CategoryEditorFetchData(
                mode: .create,
                loadingState: .loaded,
                draft: CategoryEditorDraft(name: "", emoji: "😀", colorHex: "#A0E7E5")
            )
        )
    }
}

// MARK: - handleTapCustomColorButton

extension CategoryEditorInteractorTests {
    func testHandleTapCustomColorButtonOpensColorPickerWithCurrentColor() async {
        // Arrange
        await sut.fetchData()

        // Act
        await sut.handleTapCustomColorButton()

        // Assert
        XCTAssertEqual(router.openColorPickerSelectedHexReceivedInvocations, ["#FFFFFF"])
    }
}

// MARK: - handleDidSelectCustomColor

extension CategoryEditorInteractorTests {
    func testHandleDidSelectCustomColorUpdatesDraftColor() async {
        // Arrange
        await sut.fetchData()

        // Act
        await sut.handleDidSelectCustomColor("#654321")

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations.last,
            CategoryEditorFetchData(
                mode: .create,
                loadingState: .loaded,
                draft: CategoryEditorDraft(name: "", emoji: "😀", colorHex: "#654321")
            )
        )
    }
}

// MARK: - handleTapDeleteButton

extension CategoryEditorInteractorTests {
    func testHandleTapDeleteButtonOpensDeleteConfirmation() async throws {
        // Arrange
        let sut = makeEditSut()
        observer.currentCategorySnapshotIdReturnValue = MainFlowCategorySnapshot(
            categoryID: "food",
            category: Self.foodCategory
        )
        observer.currentCategoriesSnapshotReturnValue = MainFlowCategoriesSnapshot()
        colorProvider.normalizedHexFromClosure = { $0 }
        presetProvider.emojiPresetsReturnValue = ["😀", "🍔"]
        presetProvider.colorPresetsReturnValue = ["#FFFFFF", "#A0E7E5"]
        await sut.fetchData()

        // Act
        await sut.handleTapDeleteButton()

        // Assert
        let context = try XCTUnwrap(router.openConfirmationContextReceivedArguments)
        XCTAssertEqual(
            context,
            CommonConfirmationContext(
                title: L10n.categoryEditorDeleteButton,
                subtitle: L10n.categoryEditorDeleteConfirmationTitle,
                confirmButtonTitle: L10n.categoryEditorDeleteButton,
                confirmButtonStyle: .destructive,
                cancelButtonTitle: L10n.commonCancel,
                cancelButtonStyle: .primary,
                confirmCommand: context.confirmCommand
            )
        )
        XCTAssertFalse(repository.deleteCategoryIdCalled)
    }

    func testDeleteConfirmationCommandDeletesCategoryAndCloses() async throws {
        // Arrange
        let sut = makeEditSut()
        observer.currentCategorySnapshotIdReturnValue = MainFlowCategorySnapshot(
            categoryID: "food",
            category: Self.foodCategory
        )
        observer.currentCategoriesSnapshotReturnValue = MainFlowCategoriesSnapshot()
        colorProvider.normalizedHexFromClosure = { $0 }
        presetProvider.emojiPresetsReturnValue = ["😀", "🍔"]
        presetProvider.colorPresetsReturnValue = ["#FFFFFF", "#A0E7E5"]
        await sut.fetchData()
        await sut.handleTapDeleteButton()
        let context = try XCTUnwrap(router.openConfirmationContextReceivedArguments)

        // Act
        await context.confirmCommand.executeAsync()

        // Assert
        XCTAssertEqual(repository.deleteCategoryIdReceivedInvocations, ["food"])
        XCTAssertEqual(router.closeCallsCount, 1)
    }

    func testDeleteConfirmationCommandWhenDeleteFailsPresentsError() async throws {
        // Arrange
        let sut = makeEditSut()
        observer.currentCategorySnapshotIdReturnValue = MainFlowCategorySnapshot(
            categoryID: "food",
            category: Self.foodCategory
        )
        observer.currentCategoriesSnapshotReturnValue = MainFlowCategoriesSnapshot()
        colorProvider.normalizedHexFromClosure = { $0 }
        presetProvider.emojiPresetsReturnValue = ["😀", "🍔"]
        presetProvider.colorPresetsReturnValue = ["#FFFFFF", "#A0E7E5"]
        repository.deleteCategoryIdThrowableError = TestError.any
        await sut.fetchData()
        await sut.handleTapDeleteButton()
        let context = try XCTUnwrap(router.openConfirmationContextReceivedArguments)

        // Act
        await context.confirmCommand.executeAsync()

        // Assert
        XCTAssertEqual(router.presentErrorWithReceivedInvocations, [L10n.mainOverviewError])
        XCTAssertFalse(router.closeCalled)
    }
}

// MARK: - handleTapBackButton

extension CategoryEditorInteractorTests {
    func testHandleTapBackButtonCloses() async {
        // Act
        await sut.handleTapBackButton()

        // Assert
        XCTAssertEqual(router.closeCallsCount, 1)
    }
}

// MARK: - handleSubscriptionDidSync

extension CategoryEditorInteractorTests {
    func testHandleSubscriptionDidSyncRefreshesTier() async {
        // Arrange
        subscriptionAccessService.refreshCurrentTierStateReturnValue = .resolved(.premium)

        // Act
        await sut.handleSubscriptionDidSync()

        // Assert
        XCTAssertEqual(subscriptionAccessService.refreshCurrentTierStateCallsCount, 1)
    }
}

private extension CategoryEditorInteractorTests {
    static let defaultDraft = CategoryEditorDraft(name: "", emoji: "😀", colorHex: "#FFFFFF")
    static let foodDraft = CategoryEditorDraft(name: "Food", emoji: "🍕", colorHex: "#123456")
    static let foodCategory = MainCategoryCardModel(
        id: "food",
        name: "Food",
        icon: "🍕",
        color: "#123456",
        amount: 12,
        currency: "USD"
    )

    func makeEditSut() -> CategoryEditorInteractor {
        CategoryEditorInteractor(
            mode: .edit(id: "food"),
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            subscriptionAccessService: subscriptionAccessService,
            subscriptionLimitErrorResolver: subscriptionLimitErrorResolver,
            presetProvider: presetProvider,
            colorProvider: colorProvider,
            analytics: analytics
        )
    }
}
