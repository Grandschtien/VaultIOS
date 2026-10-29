import XCTest
@testable import Vylok

@MainActor
final class LoginInteractorTests: XCTestCase {
    private var authVerificationService: AuthVerificationContractServicingMock!
    private var presenter: LoginPresentationLogicMock!
    private var router: LoginRoutingLogicMock!
    private var tokenStorage: TokenStorageServiceProtocolMock!
    private var subscriptionInitializer: SubscriptionInitializerLogicMock!
    private var profileStorage: UserProfileStorageServiceProtocolMock!
    private var widgetSnapshotSyncService: VylokWidgetSnapshotSyncingMock!

    override func setUp() {
        super.setUp()
        authVerificationService = AuthVerificationContractServicingMock()
        presenter = LoginPresentationLogicMock()
        router = LoginRoutingLogicMock()
        tokenStorage = TokenStorageServiceProtocolMock()
        subscriptionInitializer = SubscriptionInitializerLogicMock()
        profileStorage = UserProfileStorageServiceProtocolMock()
        widgetSnapshotSyncService = VylokWidgetSnapshotSyncingMock()
    }

    override func tearDown() {
        widgetSnapshotSyncService = nil
        profileStorage = nil
        subscriptionInitializer = nil
        tokenStorage = nil
        router = nil
        presenter = nil
        authVerificationService = nil
        super.tearDown()
    }
}

// MARK: - handleSignInDidTap

extension LoginInteractorTests {
    func testHandleSignInDidTapWhenLoginSucceedsStoresSessionAndOpensMainFlow() async {
        // Arrange
        let sut = LoginInteractor(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            tokenStorageService: tokenStorage,
            subscriptionInitializerLogic: subscriptionInitializer,
            userProfileStorageService: profileStorage,
            widgetSnapshotSyncService: widgetSnapshotSyncService
        )
        authVerificationService.loginReturnValue = LoginResponseDTOFixtures.makeResponse(
            tokenType: "bearer",
            expiresIn: 3600,
            user: LoginResponseDTOFixtures.makeUser(
                id: "1",
                email: "name@example.com",
                name: "Egor",
                preferredLanguage: "en-US",
                tier: "free"
            )
        )
        await sut.handleEmailDidChange("name@example.com")
        await sut.handlePasswordDidChange("12345678")

        // Act
        await sut.handleSignInDidTap()

        // Assert
        XCTAssertEqual(
            authVerificationService.loginReceivedInvocations,
            [LoginRequestDTO(provider: .password, email: "name@example.com", password: "12345678")]
        )
        XCTAssertEqual(
            tokenStorage.setTokenReceivedInvocations,
            [AuthTokenDTO(accessToken: "access", refreshToken: "refresh", tokenType: "bearer", expiresIn: 3600)]
        )
        XCTAssertEqual(
            profileStorage.saveProfileReceivedInvocations,
            [
                UserProfileDefaults(
                    userId: "1",
                    email: "name@example.com",
                    name: "Egor",
                    currency: "USD",
                    language: "en-US"
                )
            ]
        )
        XCTAssertEqual(router.openMainFlowCallsCount, 1)
        XCTAssertFalse(router.presentErrorWithCalled)
        XCTAssertFalse(router.openEmailVerificationContextCalled)
        XCTAssertFalse(widgetSnapshotSyncService.syncSnapshotCalled)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.loadingState, .loaded)
    }

    func testHandleSignInDidTapWhenLoginReturnsUnverifiedOpensEmailVerification() async {
        // Arrange
        let sut = LoginInteractor(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            tokenStorageService: tokenStorage,
            subscriptionInitializerLogic: subscriptionInitializer,
            userProfileStorageService: profileStorage,
            widgetSnapshotSyncService: widgetSnapshotSyncService
        )
        authVerificationService.loginThrowableError = AuthVerificationContractError.unverified(
            AuthVerificationChallenge(email: "name@example.com", expiresIn: 600, resendAvailableIn: 60)
        )
        await sut.handleEmailDidChange("name@example.com")
        await sut.handlePasswordDidChange("12345678")

        // Act
        await sut.handleSignInDidTap()

        // Assert
        XCTAssertFalse(router.openMainFlowCalled)
        XCTAssertFalse(router.presentErrorWithCalled)
        XCTAssertEqual(
            router.openEmailVerificationContextReceivedInvocations,
            [
                EmailVerificationContext(
                    source: .login,
                    email: "name@example.com",
                    expiresIn: 600,
                    resendAvailableIn: 60
                )
            ]
        )
    }

    func testHandleSignInDidTapWhenEmailIsEmptyPresentsValidationError() async {
        // Arrange
        let sut = LoginInteractor(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            tokenStorageService: tokenStorage,
            subscriptionInitializerLogic: subscriptionInitializer,
            userProfileStorageService: profileStorage,
            widgetSnapshotSyncService: widgetSnapshotSyncService
        )
        await sut.handlePasswordDidChange("12345678")

        // Act
        await sut.handleSignInDidTap()

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations.last?.loadingState,
            .failed(.undelinedError(description: LoginInteractor.LocalError.emptyEmail.localizedDescription))
        )
        XCTAssertFalse(authVerificationService.loginCalled)
        XCTAssertFalse(router.openMainFlowCalled)
        XCTAssertFalse(router.presentErrorWithCalled)
        XCTAssertFalse(profileStorage.saveProfileCalled)
    }

    func testHandleSignInDidTapWhenLoginFailsPresentsError() async {
        // Arrange
        let sut = LoginInteractor(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            tokenStorageService: tokenStorage,
            subscriptionInitializerLogic: subscriptionInitializer,
            userProfileStorageService: profileStorage,
            widgetSnapshotSyncService: widgetSnapshotSyncService
        )
        authVerificationService.loginThrowableError = TestError.any
        await sut.handleEmailDidChange("name@example.com")
        await sut.handlePasswordDidChange("12345678")

        // Act
        await sut.handleSignInDidTap()

        // Assert
        guard case .failed = presenter.presentFetchedDataReceivedInvocations.last?.loadingState else {
            return XCTFail("Expected failed state")
        }
        XCTAssertEqual(router.presentErrorWithCallsCount, 1)
        XCTAssertFalse(router.openMainFlowCalled)
        XCTAssertFalse(profileStorage.saveProfileCalled)
    }
}

// MARK: - handleForgotDidTap

extension LoginInteractorTests {
    func testHandleForgotDidTapOpensForgotPasswordWithCurrentEmail() async {
        // Arrange
        let sut = LoginInteractor(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            tokenStorageService: tokenStorage,
            subscriptionInitializerLogic: subscriptionInitializer,
            userProfileStorageService: profileStorage,
            widgetSnapshotSyncService: widgetSnapshotSyncService
        )
        await sut.handleEmailDidChange("name@example.com")

        // Act
        await sut.handleForgotDidTap()

        // Assert
        XCTAssertEqual(
            router.openForgetPasswordScreenContextReceivedInvocations,
            [ForgotPasswordContext(email: "name@example.com")]
        )
    }
}
