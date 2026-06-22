import XCTest
@testable import Vault

@MainActor
final class LoginInteractorTests: XCTestCase {
    func testSignInHappyPathStoresTokenAndOpensMainFlow() async {
        let authVerificationService = AuthVerificationContractServiceSpy()
        authVerificationService.loginResult = .success(
            LoginResponseDTO(
                accessToken: "access",
                refreshToken: "refresh",
                tokenType: "bearer",
                expiresIn: 3600,
                user: .init(
                    id: "1",
                    email: "name@example.com",
                    emailVerified: true,
                    name: "Egor",
                    currency: "USD",
                    preferredLanguage: "en-US",
                    tier: "free"
                )
            )
        )

        let presenter = LoginPresenterSpy()
        let router = LoginRouterSpy()
        let tokenStorage = TokenStorageSpy()
        let profileStorage = UserProfileStorageSpy()
        let sut = makeSut(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            tokenStorage: tokenStorage,
            profileStorage: profileStorage
        )

        await sut.handleEmailDidChange("name@example.com")
        await sut.handlePasswordDidChange("12345678")
        await sut.handleSignInDidTap()

        XCTAssertEqual(
            authVerificationService.loginRequests,
            [
                LoginRequestDTO(
                    provider: .password,
                    email: "name@example.com",
                    password: "12345678"
                )
            ]
        )
        XCTAssertEqual(
            tokenStorage.savedToken,
            AuthTokenDTO(
                accessToken: "access",
                refreshToken: "refresh",
                tokenType: "bearer",
                expiresIn: 3600
            )
        )
        XCTAssertEqual(
            profileStorage.savedProfile,
            UserProfileDefaults(
                userId: "1",
                email: "name@example.com",
                name: "Egor",
                currency: "USD",
                language: "en-US"
            )
        )
        XCTAssertEqual(router.openedMainFlowCount, 1)
        XCTAssertTrue(router.presentedErrors.isEmpty)
        XCTAssertTrue(router.emailVerificationContexts.isEmpty)

        guard let lastData = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        if case .loaded = lastData.loadingState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected loaded state")
        }
    }

    func testSignInWhenLoginReturnsUnverifiedOpensEmailVerification() async {
        let authVerificationService = AuthVerificationContractServiceSpy()
        authVerificationService.loginResult = .failure(
            AuthVerificationContractError.unverified(
                AuthVerificationChallenge(
                    email: "name@example.com",
                    expiresIn: 600,
                    resendAvailableIn: 60
                )
            )
        )
        let presenter = LoginPresenterSpy()
        let router = LoginRouterSpy()
        let sut = makeSut(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            tokenStorage: TokenStorageSpy(),
            profileStorage: UserProfileStorageSpy()
        )

        await sut.handleEmailDidChange("name@example.com")
        await sut.handlePasswordDidChange("12345678")
        await sut.handleSignInDidTap()

        XCTAssertEqual(router.openedMainFlowCount, 0)
        XCTAssertTrue(router.presentedErrors.isEmpty)
        XCTAssertEqual(
            router.emailVerificationContexts,
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

    func testSignInWithEmptyEmailDoesNotOpenMainFlow() async {
        let presenter = LoginPresenterSpy()
        let router = LoginRouterSpy()
        let profileStorage = UserProfileStorageSpy()
        let sut = makeSut(
            authVerificationService: AuthVerificationContractServiceSpy(),
            presenter: presenter,
            router: router,
            tokenStorage: TokenStorageSpy(),
            profileStorage: profileStorage
        )

        await sut.handlePasswordDidChange("12345678")
        await sut.handleSignInDidTap()

        XCTAssertEqual(router.openedMainFlowCount, 0)
        XCTAssertTrue(router.presentedErrors.isEmpty)

        guard let lastData = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        guard case let .failed(error) = lastData.loadingState else {
            return XCTFail("Expected failed state")
        }

        guard case let .undelinedError(description) = error else {
            return XCTFail("Expected wrapped validation error")
        }

        XCTAssertEqual(
            description,
            LoginInteractor.LocalError.emptyEmail.localizedDescription
        )

        XCTAssertNil(profileStorage.savedProfile)
    }

    func testSignInFailurePresentsErrorAndDoesNotOpenMainFlow() async {
        let authVerificationService = AuthVerificationContractServiceSpy()
        authVerificationService.loginResult = .failure(StubError.any)
        let presenter = LoginPresenterSpy()
        let router = LoginRouterSpy()
        let profileStorage = UserProfileStorageSpy()
        let sut = makeSut(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            tokenStorage: TokenStorageSpy(),
            profileStorage: profileStorage
        )

        await sut.handleEmailDidChange("name@example.com")
        await sut.handlePasswordDidChange("12345678")
        await sut.handleSignInDidTap()

        XCTAssertEqual(router.presentedErrors.count, 1)
        XCTAssertEqual(router.openedMainFlowCount, 0)

        guard let lastData = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        if case .failed = lastData.loadingState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected failed state")
        }

        XCTAssertNil(profileStorage.savedProfile)
    }

    func testHandleForgotDidTapOpensForgotPasswordWithCurrentEmail() async {
        let router = LoginRouterSpy()
        let sut = makeSut(
            authVerificationService: AuthVerificationContractServiceSpy(),
            presenter: LoginPresenterSpy(),
            router: router,
            tokenStorage: TokenStorageSpy(),
            profileStorage: UserProfileStorageSpy()
        )

        await sut.handleEmailDidChange("name@example.com")
        await sut.handleForgotDidTap()

        XCTAssertEqual(
            router.forgotPasswordContexts,
            [ForgotPasswordContext(email: "name@example.com")]
        )
    }
}

private extension LoginInteractorTests {
    func makeSut(
        authVerificationService: AuthVerificationContractServicing,
        presenter: LoginPresentationLogic,
        router: LoginRoutingLogic,
        tokenStorage: TokenStorageServiceProtocol,
        profileStorage: UserProfileStorageServiceProtocol
    ) -> LoginInteractor {
        LoginInteractor(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            tokenStorageService: tokenStorage,
            subscriptionInitializerLogic: SubscriptionInitializerSpy(),
            userProfileStorageService: profileStorage,
            widgetSnapshotSyncService: WidgetSnapshotSyncSpy()
        )
    }

    enum StubError: LocalizedError {
        case any

        var errorDescription: String? {
            "stub-error"
        }
    }
}

private final class WidgetSnapshotSyncSpy: VaultWidgetSnapshotSyncing, @unchecked Sendable {
    func syncSnapshot() async {}

    func clearSnapshot() {}
}

private final class AuthVerificationContractServiceSpy: AuthVerificationContractServicing, @unchecked Sendable {
    var startRegistrationResult: Result<EmailVerificationChallengeResponseDTO, Error> = .failure(LoginInteractorTests.StubError.any)
    var verifyResult: Result<LoginResponseDTO, Error> = .failure(LoginInteractorTests.StubError.any)
    var resendResult: Result<EmailVerificationChallengeResponseDTO, Error> = .failure(LoginInteractorTests.StubError.any)
    var loginResult: Result<LoginResponseDTO, Error> = .failure(LoginInteractorTests.StubError.any)

    private(set) var loginRequests: [LoginRequestDTO] = []

    func startEmailRegistration(_ request: RegisterRequestDTO) async throws -> EmailVerificationChallengeResponseDTO {
        switch startRegistrationResult {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }

    func verifyEmail(_ request: EmailVerificationRequestDTO) async throws -> LoginResponseDTO {
        switch verifyResult {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }

    func resendEmailVerification(_ request: EmailVerificationResendRequestDTO) async throws -> EmailVerificationChallengeResponseDTO {
        switch resendResult {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }

    func login(_ request: LoginRequestDTO) async throws -> LoginResponseDTO {
        loginRequests.append(request)

        switch loginResult {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }
}

@MainActor
private final class LoginPresenterSpy: LoginPresentationLogic, @unchecked Sendable {
    private(set) var presentedData: [LoginFetchData] = []

    func presentFetchedData(_ data: LoginFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class LoginRouterSpy: LoginRoutingLogic, @unchecked Sendable {
    private(set) var openedMainFlowCount: Int = .zero
    private(set) var presentedErrors: [String] = []
    private(set) var emailVerificationContexts: [EmailVerificationContext] = []
    private(set) var forgotPasswordContexts: [ForgotPasswordContext] = []

    func openRegistration() {}

    func openEmailVerification(context: EmailVerificationContext) {
        emailVerificationContexts.append(context)
    }

    func openMainFlow() {
        openedMainFlowCount += 1
    }

    func openForgetPasswordScreen(context: ForgotPasswordContext) {
        forgotPasswordContexts.append(context)
    }

    func presentError(with text: String) {
        presentedErrors.append(text)
    }
}

private final class TokenStorageSpy: TokenStorageServiceProtocol, @unchecked Sendable {
    private(set) var savedToken: AuthTokenDTO?

    func setToken(_ token: AuthTokenDTO) {
        savedToken = token
    }

    func getToken() -> AuthTokenDTO? {
        savedToken
    }

    func removeToken() {
        savedToken = nil
    }
}

private final class UserProfileStorageSpy: UserProfileStorageServiceProtocol, @unchecked Sendable {
    private(set) var savedProfile: UserProfileDefaults?

    func saveProfile(_ profile: UserProfileDefaults) {
        savedProfile = profile
    }

    func loadProfile() -> UserProfileDefaults? {
        savedProfile
    }

    func clearProfile() {
        savedProfile = nil
    }
}

private actor SubscriptionInitializerSpy: SubscriptionInitializerLogic {
    func initialize() async {}
    func setUserId(_ id: String) async {}
    func logout() async {}
}
