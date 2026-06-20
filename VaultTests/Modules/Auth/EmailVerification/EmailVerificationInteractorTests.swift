import XCTest
@testable import Vault

@MainActor
final class EmailVerificationInteractorTests: XCTestCase {
    func testFetchDataPresentsInitialState() async {
        let presenter = EmailVerificationPresenterSpy()
        let sut = makeSut(
            presenter: presenter,
            context: EmailVerificationContext(
                source: .login,
                email: "jane@example.com",
                expiresIn: 600,
                resendAvailableIn: 60
            )
        )

        await sut.fetchData()

        XCTAssertEqual(presenter.presentedData.last?.email, "jane@example.com")
        XCTAssertEqual(presenter.presentedData.last?.resendAvailableIn, 60)
    }

    func testHandleCodeDidChangeWithPartialCodeDoesNotShowValidationError() async {
        let presenter = EmailVerificationPresenterSpy()
        let sut = makeSut(presenter: presenter)

        await sut.handleCodeDidChange("123")

        XCTAssertEqual(presenter.presentedData.last?.code, "123")
        XCTAssertNil(presenter.presentedData.last?.errorMessage)
    }

    func testHandleCodeDidChangeWithFullCodeAutoVerifiesAndShowsInlineError() async {
        let presenter = EmailVerificationPresenterSpy()
        let service = AuthVerificationContractServiceSpy()
        service.verifyResult = .failure(.invalidCode)
        let sut = makeSut(
            service: service,
            presenter: presenter
        )

        await sut.handleCodeDidChange("123456")

        XCTAssertEqual(presenter.presentedData.last?.errorMessage, L10n.emailVerificationInvalidCode)
    }

    func testHandleCodeDidChangeWithFullCodeSuccessSavesSessionClearsRegistrationStorageAndOpensMainFlow() async {
        let service = AuthVerificationContractServiceSpy()
        service.verifyResult = .success(
            LoginResponseDTO(
                accessToken: "access",
                refreshToken: "refresh",
                tokenType: "Bearer",
                expiresIn: 900,
                user: .init(
                    id: "1",
                    email: "jane@example.com",
                    emailVerified: true,
                    name: "Jane Doe",
                    currency: "USD",
                    preferredLanguage: "en",
                    tier: "REGULAR"
                )
            )
        )
        let router = EmailVerificationRouterSpy()
        let tokenStorage = TokenStorageSpy()
        let profileStorage = UserProfileStorageSpy()
        let registrationStorage = RegistrationStorage()
        await registrationStorage.saveDraft(
            RegistrationDraft(
                email: "jane@example.com",
                password: "secret123",
                confirmPassword: "secret123",
                name: "Jane Doe",
                currencyCode: "USD"
            )
        )
        let subscriptionInitializer = SubscriptionInitializerSpy()
        let sut = makeSut(
            service: service,
            router: router,
            tokenStorage: tokenStorage,
            profileStorage: profileStorage,
            subscriptionInitializer: subscriptionInitializer,
            context: EmailVerificationContext(
                source: .registration,
                email: "jane@example.com",
                expiresIn: 600,
                resendAvailableIn: 0
            ),
            registrationStorage: registrationStorage
        )

        await sut.handleCodeDidChange("123456")

        XCTAssertEqual(router.openMainFlowCallsCount, 1)
        XCTAssertEqual(
            tokenStorage.savedToken,
            AuthTokenDTO(
                accessToken: "access",
                refreshToken: "refresh",
                tokenType: "Bearer",
                expiresIn: 900
            )
        )
        XCTAssertEqual(
            profileStorage.savedProfile,
            UserProfileDefaults(
                userId: "1",
                email: "jane@example.com",
                name: "Jane Doe",
                currency: "USD",
                language: "en"
            )
        )
        XCTAssertEqual(await subscriptionInitializer.capturedUserIds(), ["1"])
        XCTAssertEqual(await registrationStorage.loadDraft(), .init())
    }

    func testHandleTapResendSuccessResetsCodeErrorAndCooldown() async {
        let presenter = EmailVerificationPresenterSpy()
        let service = AuthVerificationContractServiceSpy()
        service.resendResult = .success(
            EmailVerificationChallengeResponseDTO(
                status: "code_sent",
                email: "jane@example.com",
                expiresIn: 600,
                resendAvailableIn: 60
            )
        )
        let sut = makeSut(
            service: service,
            presenter: presenter,
            context: EmailVerificationContext(
                source: .login,
                email: "jane@example.com",
                expiresIn: 600,
                resendAvailableIn: 0
            )
        )

        await sut.handleCodeDidChange("123")
        await sut.handleTapResend()

        XCTAssertEqual(presenter.presentedData.last?.code, "")
        XCTAssertNil(presenter.presentedData.last?.errorMessage)
        XCTAssertEqual(presenter.presentedData.last?.resendAvailableIn, 60)
    }

    func testHandleTapResendFailurePreservesStateAndShowsToastError() async {
        let presenter = EmailVerificationPresenterSpy()
        let router = EmailVerificationRouterSpy()
        let service = AuthVerificationContractServiceSpy()
        service.resendResult = .failure(.resendTooSoon)
        let sut = makeSut(
            service: service,
            presenter: presenter,
            router: router,
            context: EmailVerificationContext(
                source: .login,
                email: "jane@example.com",
                expiresIn: 600,
                resendAvailableIn: 0
            )
        )

        await sut.handleCodeDidChange("123456")
        await sut.handleTapResend()

        XCTAssertEqual(presenter.presentedData.last?.code, "123456")
        XCTAssertEqual(router.presentedErrors, [L10n.authVerificationErrorResendTooSoon])
    }
}

private extension EmailVerificationInteractorTests {
    @MainActor
    func makeSut(
        service: AuthVerificationContractServicing = AuthVerificationContractServiceSpy(),
        presenter: EmailVerificationPresentationLogic = EmailVerificationPresenterSpy(),
        router: EmailVerificationRoutingLogic = EmailVerificationRouterSpy(),
        tokenStorage: TokenStorageServiceProtocol = TokenStorageSpy(),
        profileStorage: UserProfileStorageServiceProtocol = UserProfileStorageSpy(),
        subscriptionInitializer: SubscriptionInitializerLogic = SubscriptionInitializerSpy(),
        context: EmailVerificationContext = .init(
            source: .login,
            email: "jane@example.com",
            expiresIn: 600,
            resendAvailableIn: 0
        ),
        registrationStorage: RegistrationStorageProtocol? = nil
    ) -> EmailVerificationInteractor {
        EmailVerificationInteractor(
            authVerificationService: service,
            presenter: presenter,
            router: router,
            tokenStorageService: tokenStorage,
            userProfileStorageService: profileStorage,
            subscriptionInitializer: subscriptionInitializer,
            context: context,
            registrationStorage: registrationStorage
        )
    }
}

private final class AuthVerificationContractServiceSpy: AuthVerificationContractServicing, @unchecked Sendable {
    var startRegistrationResult: Result<EmailVerificationChallengeResponseDTO, Error> = .failure(AuthVerificationContractError.serverError)
    var verifyResult: Result<LoginResponseDTO, Error> = .failure(AuthVerificationContractError.serverError)
    var resendResult: Result<EmailVerificationChallengeResponseDTO, Error> = .failure(AuthVerificationContractError.serverError)
    var loginResult: Result<LoginResponseDTO, Error> = .failure(AuthVerificationContractError.serverError)

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
        switch loginResult {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }
}

@MainActor
private final class EmailVerificationPresenterSpy: EmailVerificationPresentationLogic, @unchecked Sendable {
    private(set) var presentedData: [EmailVerificationFetchData] = []

    func presentFetchedData(_ data: EmailVerificationFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class EmailVerificationRouterSpy: EmailVerificationRoutingLogic, @unchecked Sendable {
    private(set) var openMainFlowCallsCount = 0
    private(set) var presentedErrors: [String] = []

    func openMainFlow() {
        openMainFlowCallsCount += 1
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
    private var userIds: [String] = []

    func initialize() async {}

    func setUserId(_ id: String) async {
        userIds.append(id)
    }

    func logout() async {}

    func capturedUserIds() async -> [String] {
        userIds
    }
}
