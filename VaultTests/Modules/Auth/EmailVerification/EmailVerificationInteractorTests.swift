import XCTest
@testable import Vylok

final class EmailVerificationInteractorTests: XCTestCase {
    private var authVerificationService: AuthVerificationContractServicingMock!
    private var presenter: EmailVerificationPresentationLogicMock!
    private var router: EmailVerificationRoutingLogicMock!
    private var tokenStorageService: TokenStorageServiceProtocolMock!
    private var userProfileStorageService: UserProfileStorageServiceProtocolMock!
    private var subscriptionInitializer: SubscriptionInitializerLogicMock!
    private var widgetSnapshotSyncService: VylokWidgetSnapshotSyncingMock!
    private var registrationStorage: RegistrationStorageProtocolMock!
    private var sut: EmailVerificationInteractor!

    override func setUp() {
        super.setUp()
        authVerificationService = AuthVerificationContractServicingMock()
        presenter = EmailVerificationPresentationLogicMock()
        router = EmailVerificationRoutingLogicMock()
        tokenStorageService = TokenStorageServiceProtocolMock()
        userProfileStorageService = UserProfileStorageServiceProtocolMock()
        subscriptionInitializer = SubscriptionInitializerLogicMock()
        widgetSnapshotSyncService = VylokWidgetSnapshotSyncingMock()
        registrationStorage = RegistrationStorageProtocolMock()
        sut = EmailVerificationInteractor(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            tokenStorageService: tokenStorageService,
            userProfileStorageService: userProfileStorageService,
            subscriptionInitializer: subscriptionInitializer,
            widgetSnapshotSyncService: widgetSnapshotSyncService,
            context: EmailVerificationContext(
                source: .registration,
                email: "jane@example.com",
                expiresIn: 600,
                resendAvailableIn: 0
            ),
            registrationStorage: registrationStorage
        )
    }

    override func tearDown() {
        sut = nil
        registrationStorage = nil
        widgetSnapshotSyncService = nil
        subscriptionInitializer = nil
        userProfileStorageService = nil
        tokenStorageService = nil
        router = nil
        presenter = nil
        authVerificationService = nil
        super.tearDown()
    }
}

// MARK: - fetchData

extension EmailVerificationInteractorTests {
    func testFetchDataPresentsEmailFromContext() async {
        // Act
        await sut.fetchData()

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [EmailVerificationFetchData(loadingState: .idle, email: "jane@example.com")]
        )
    }
}

// MARK: - handleCodeDidChange

extension EmailVerificationInteractorTests {
    func testHandleCodeDidChangeWhenCodeIsIncompleteKeepsDigitsOnlyAndDoesNotVerify() async {
        // Act
        await sut.handleCodeDidChange("12a3")

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [EmailVerificationFetchData(loadingState: .idle, email: "jane@example.com", code: "123")]
        )
        XCTAssertFalse(authVerificationService.verifyEmailCalled)
    }

    func testHandleCodeDidChangeWhenCodeIsCompleteVerifiesAppliesSessionAndOpensMainFlow() async {
        // Arrange
        authVerificationService.verifyEmailReturnValue = LoginResponseDTOFixtures.makeResponse()

        // Act
        await sut.handleCodeDidChange("123456")

        // Assert
        XCTAssertEqual(
            authVerificationService.verifyEmailReceivedInvocations,
            [EmailVerificationRequestDTO(email: "jane@example.com", code: "123456")]
        )
        XCTAssertEqual(
            tokenStorageService.setTokenReceivedInvocations,
            [AuthTokenDTO(accessToken: "access", refreshToken: "refresh", tokenType: "Bearer", expiresIn: 900)]
        )
        XCTAssertEqual(
            userProfileStorageService.saveProfileReceivedInvocations,
            [UserProfileDefaults(userId: "user-1", email: "jane@example.com", name: "Jane Doe", currency: "USD", language: "en")]
        )
        XCTAssertEqual(subscriptionInitializer.setUserIdReceivedInvocations, ["user-1"])
        XCTAssertEqual(registrationStorage.clearCallsCount, 1)
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                EmailVerificationFetchData(loadingState: .idle, email: "jane@example.com", code: "123456"),
                EmailVerificationFetchData(loadingState: .loading, email: "jane@example.com", code: "123456"),
                EmailVerificationFetchData(loadingState: .loaded, email: "jane@example.com", code: "123456")
            ]
        )
        XCTAssertEqual(router.openMainFlowCallsCount, 1)
    }

    func testHandleCodeDidChangeWhenSourceIsLoginDoesNotClearRegistrationDraft() async {
        // Arrange
        let sut = EmailVerificationInteractor(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            tokenStorageService: tokenStorageService,
            userProfileStorageService: userProfileStorageService,
            subscriptionInitializer: subscriptionInitializer,
            widgetSnapshotSyncService: widgetSnapshotSyncService,
            context: EmailVerificationContext(
                source: .login,
                email: "jane@example.com",
                expiresIn: 600,
                resendAvailableIn: 0
            ),
            registrationStorage: registrationStorage
        )
        authVerificationService.verifyEmailReturnValue = LoginResponseDTOFixtures.makeResponse()

        // Act
        await sut.handleCodeDidChange("123456")

        // Assert
        XCTAssertFalse(registrationStorage.clearCalled)
        XCTAssertEqual(router.openMainFlowCallsCount, 1)
    }

    func testHandleCodeDidChangeWhenCodeIsInvalidShowsInlineError() async {
        // Arrange
        authVerificationService.verifyEmailThrowableError = AuthVerificationContractError.invalidCode

        // Act
        await sut.handleCodeDidChange("123456")

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                EmailVerificationFetchData(loadingState: .idle, email: "jane@example.com", code: "123456"),
                EmailVerificationFetchData(loadingState: .loading, email: "jane@example.com", code: "123456"),
                EmailVerificationFetchData(
                    loadingState: .idle,
                    email: "jane@example.com",
                    code: "123456",
                    errorMessage: L10n.emailVerificationInvalidCode
                )
            ]
        )
        XCTAssertFalse(router.presentErrorWithCalled)
        XCTAssertFalse(router.openMainFlowCalled)
    }

    func testHandleCodeDidChangeWhenContractErrorHasNoInlineMessagePresentsErrorAlert() async {
        // Arrange
        authVerificationService.verifyEmailThrowableError = AuthVerificationContractError.serverError

        // Act
        await sut.handleCodeDidChange("123456")

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                EmailVerificationFetchData(loadingState: .idle, email: "jane@example.com", code: "123456"),
                EmailVerificationFetchData(loadingState: .loading, email: "jane@example.com", code: "123456"),
                EmailVerificationFetchData(loadingState: .idle, email: "jane@example.com", code: "123456")
            ]
        )
        XCTAssertEqual(
            router.presentErrorWithReceivedInvocations,
            [AuthVerificationContractError.serverError.localizedDescription]
        )
        XCTAssertFalse(router.openMainFlowCalled)
    }

    func testHandleCodeDidChangeWhenUnexpectedErrorPresentsFailedStateAndErrorAlert() async {
        // Arrange
        authVerificationService.verifyEmailThrowableError = TestError.any

        // Act
        await sut.handleCodeDidChange("123456")

        // Assert
        let errorDescription = TestError.any.localizedDescription
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                EmailVerificationFetchData(loadingState: .idle, email: "jane@example.com", code: "123456"),
                EmailVerificationFetchData(loadingState: .loading, email: "jane@example.com", code: "123456"),
                EmailVerificationFetchData(
                    loadingState: .failed(.undelinedError(description: errorDescription)),
                    email: "jane@example.com",
                    code: "123456"
                )
            ]
        )
        XCTAssertEqual(router.presentErrorWithReceivedInvocations, [errorDescription])
        XCTAssertFalse(router.openMainFlowCalled)
    }
}

// MARK: - handleTapVerify

extension EmailVerificationInteractorTests {
    func testHandleTapVerifyWhenCodeIsIncompleteShowsFillFieldError() async {
        // Act
        await sut.handleTapVerify()

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                EmailVerificationFetchData(
                    loadingState: .idle,
                    email: "jane@example.com",
                    errorMessage: L10n.commonFillField
                )
            ]
        )
        XCTAssertFalse(authVerificationService.verifyEmailCalled)
    }
}

// MARK: - handleTapResend

extension EmailVerificationInteractorTests {
    func testHandleTapResendWhenCountdownIsOverResendsAndResetsCode() async {
        // Arrange
        authVerificationService.resendEmailVerificationReturnValue = EmailVerificationChallengeResponseDTO(
            status: "code_sent",
            email: "jane@example.com",
            expiresIn: 600,
            resendAvailableIn: 0
        )
        await sut.handleCodeDidChange("12")

        // Act
        await sut.handleTapResend()

        // Assert
        XCTAssertEqual(
            authVerificationService.resendEmailVerificationReceivedInvocations,
            [EmailVerificationResendRequestDTO(email: "jane@example.com")]
        )
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                EmailVerificationFetchData(loadingState: .idle, email: "jane@example.com", code: "12"),
                EmailVerificationFetchData(loadingState: .loading, email: "jane@example.com", code: "12"),
                EmailVerificationFetchData(loadingState: .loaded, email: "jane@example.com")
            ]
        )
    }

    func testHandleTapResendWhenCountdownIsActiveDoesNothing() async {
        // Arrange
        let sut = EmailVerificationInteractor(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            tokenStorageService: tokenStorageService,
            userProfileStorageService: userProfileStorageService,
            subscriptionInitializer: subscriptionInitializer,
            widgetSnapshotSyncService: widgetSnapshotSyncService,
            context: EmailVerificationContext(
                source: .registration,
                email: "jane@example.com",
                expiresIn: 600,
                resendAvailableIn: 30
            ),
            registrationStorage: registrationStorage
        )

        // Act
        await sut.handleTapResend()

        // Assert
        XCTAssertFalse(authVerificationService.resendEmailVerificationCalled)
        XCTAssertFalse(presenter.presentFetchedDataCalled)
    }

    func testHandleTapResendWhenContractErrorPresentsIdleStateAndErrorAlert() async {
        // Arrange
        authVerificationService.resendEmailVerificationThrowableError = AuthVerificationContractError.resendTooSoon

        // Act
        await sut.handleTapResend()

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                EmailVerificationFetchData(loadingState: .loading, email: "jane@example.com"),
                EmailVerificationFetchData(loadingState: .idle, email: "jane@example.com")
            ]
        )
        XCTAssertEqual(
            router.presentErrorWithReceivedInvocations,
            [AuthVerificationContractError.resendTooSoon.localizedDescription]
        )
    }

    func testHandleTapResendWhenUnexpectedErrorPresentsFailedStateAndErrorAlert() async {
        // Arrange
        authVerificationService.resendEmailVerificationThrowableError = TestError.any

        // Act
        await sut.handleTapResend()

        // Assert
        let errorDescription = TestError.any.localizedDescription
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                EmailVerificationFetchData(loadingState: .loading, email: "jane@example.com"),
                EmailVerificationFetchData(
                    loadingState: .failed(.undelinedError(description: errorDescription)),
                    email: "jane@example.com"
                )
            ]
        )
        XCTAssertEqual(router.presentErrorWithReceivedInvocations, [errorDescription])
    }
}
