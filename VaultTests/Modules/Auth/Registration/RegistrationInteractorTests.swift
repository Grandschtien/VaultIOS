import XCTest
@testable import Vylok

@MainActor
final class RegistrationInteractorTests: XCTestCase {
    func testRegistrationHappyPathOpensEmailVerificationAndKeepsDraft() async {
        let authVerificationService = AuthVerificationContractServiceSpy()
        authVerificationService.startRegistrationResult = .success(
            EmailVerificationChallengeResponseDTO(
                status: "code_sent",
                email: "name@example.com",
                expiresIn: 600,
                resendAvailableIn: 60
            )
        )

        let presenter = RegistrationPresenterSpy()
        let router = RegistrationRouterSpy()
        let storage = RegistrationStorage()
        let sut = makeSut(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            storage: storage
        )

        await sut.fetchData()
        await sut.handleEmailDidChange("name@example.com")
        await sut.handlePasswordDidChange("12345678")
        await sut.handleConfirmPasswordDidChange("12345678")
        await sut.handleTapPrimaryButton()
        await sut.handleNameDidChange("Egor")
        await sut.handleTapPrimaryButton()
        await sut.handleSelectCurrency("USD")
        await sut.handleTapPrimaryButton()

        XCTAssertEqual(
            authVerificationService.startRegistrationRequests,
            [
                RegisterRequestDTO(
                    provider: "password",
                    email: "name@example.com",
                    password: "12345678",
                    name: "Egor",
                    currency: "USD",
                    preferredLanguage: "en-US"
                )
            ]
        )

        let draft = await storage.loadDraft()
        XCTAssertEqual(
            draft,
            RegistrationDraft(
                email: "name@example.com",
                password: "12345678",
                confirmPassword: "12345678",
                name: "Egor",
                currencyCode: "USD"
            )
        )

        XCTAssertTrue(router.presentedErrors.isEmpty)
        XCTAssertEqual(
            router.emailVerificationContexts,
            [
                EmailVerificationContext(
                    source: .registration,
                    email: "name@example.com",
                    expiresIn: 600,
                    resendAvailableIn: 60
                )
            ]
        )

        guard let lastPresentedData = presenter.presentedData.last else {
            return XCTFail("Expected presenter to receive data")
        }

        if case .loaded = lastPresentedData.loadingState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected loading state to be loaded")
        }
    }

    func testSecondaryButtonMovesBackKeepingEnteredValues() async {
        let presenter = RegistrationPresenterSpy()
        let router = RegistrationRouterSpy()
        let storage = RegistrationStorage()
        let sut = makeSut(
            authVerificationService: AuthVerificationContractServiceSpy(),
            presenter: presenter,
            router: router,
            storage: storage
        )

        await sut.fetchData()
        await sut.handleEmailDidChange("name@example.com")
        await sut.handlePasswordDidChange("12345678")
        await sut.handleConfirmPasswordDidChange("12345678")
        await sut.handleTapPrimaryButton()
        await sut.handleNameDidChange("Egor")
        await sut.handleTapPrimaryButton()

        await sut.handleTapSecondaryButton()

        guard let afterFirstBack = presenter.presentedData.last else {
            return XCTFail("Expected presenter update after first back")
        }

        XCTAssertEqual(afterFirstBack.step, .name)
        XCTAssertEqual(afterFirstBack.name, "Egor")

        await sut.handleTapSecondaryButton()

        guard let afterSecondBack = presenter.presentedData.last else {
            return XCTFail("Expected presenter update after second back")
        }

        XCTAssertEqual(afterSecondBack.step, .account)
        XCTAssertEqual(afterSecondBack.email, "name@example.com")
    }

    func testPrimaryButtonBlocksStepOneOnInvalidEmail() async {
        let presenter = RegistrationPresenterSpy()
        let sut = makeSut(
            authVerificationService: AuthVerificationContractServiceSpy(),
            presenter: presenter,
            router: RegistrationRouterSpy(),
            storage: RegistrationStorage()
        )

        await sut.fetchData()
        await sut.handleEmailDidChange("invalid")
        await sut.handlePasswordDidChange("12345678")
        await sut.handleConfirmPasswordDidChange("12345678")
        await sut.handleTapPrimaryButton()

        guard let lastData = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        XCTAssertEqual(lastData.step, .account)
        XCTAssertEqual(lastData.emailErrorMessage, L10n.registrationErrorInvalidEmail)
    }

    func testPrimaryButtonBlocksStepOneOnShortPassword() async {
        let presenter = RegistrationPresenterSpy()
        let sut = makeSut(
            authVerificationService: AuthVerificationContractServiceSpy(),
            presenter: presenter,
            router: RegistrationRouterSpy(),
            storage: RegistrationStorage()
        )

        await sut.fetchData()
        await sut.handleEmailDidChange("name@example.com")
        await sut.handlePasswordDidChange("1234567")
        await sut.handleConfirmPasswordDidChange("1234567")
        await sut.handleTapPrimaryButton()

        guard let lastData = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        XCTAssertEqual(lastData.step, .account)
        XCTAssertEqual(lastData.passwordErrorMessage, L10n.registrationErrorPasswordTooShort)
    }

    func testRegistrationFailurePresentsRouterError() async {
        let authVerificationService = AuthVerificationContractServiceSpy()
        authVerificationService.startRegistrationResult = .failure(StubError.any)
        let presenter = RegistrationPresenterSpy()
        let router = RegistrationRouterSpy()
        let sut = makeSut(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            storage: RegistrationStorage()
        )

        await sut.fetchData()
        await sut.handleEmailDidChange("name@example.com")
        await sut.handlePasswordDidChange("12345678")
        await sut.handleConfirmPasswordDidChange("12345678")
        await sut.handleTapPrimaryButton()
        await sut.handleNameDidChange("Egor")
        await sut.handleTapPrimaryButton()
        await sut.handleSelectCurrency("USD")
        await sut.handleTapPrimaryButton()

        XCTAssertEqual(router.presentedErrors.count, 1)
        XCTAssertTrue(router.emailVerificationContexts.isEmpty)

        guard let lastData = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        if case .failed = lastData.loadingState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected failed loading state")
        }
    }

    func testHandleFlowDidExitClearsStorage() async {
        let storage = RegistrationStorage()
        let sut = makeSut(
            authVerificationService: AuthVerificationContractServiceSpy(),
            presenter: RegistrationPresenterSpy(),
            router: RegistrationRouterSpy(),
            storage: storage
        )

        await sut.fetchData()
        await sut.handleEmailDidChange("name@example.com")

        await sut.handleFlowDidExit()

        let draft = await storage.loadDraft()
        XCTAssertEqual(draft, .init())
    }
}

private extension RegistrationInteractorTests {
    func makeSut(
        authVerificationService: AuthVerificationContractServicing,
        presenter: RegistrationPresentationLogic,
        router: RegistrationRoutingLogic,
        storage: RegistrationStorageProtocol
    ) -> RegistrationInteractor {
        RegistrationInteractor(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            registrationStorage: storage,
            currencyProvider: CurrencyProviderStub(),
            localeProvider: LocaleProviderStub()
        )
    }

    enum StubError: LocalizedError {
        case any

        var errorDescription: String? {
            "stub-error"
        }
    }
}

private final class AuthVerificationContractServiceSpy: AuthVerificationContractServicing, @unchecked Sendable {
    var startRegistrationResult: Result<EmailVerificationChallengeResponseDTO, Error> = .failure(RegistrationInteractorTests.StubError.any)
    var verifyResult: Result<LoginResponseDTO, Error> = .failure(RegistrationInteractorTests.StubError.any)
    var resendResult: Result<EmailVerificationChallengeResponseDTO, Error> = .failure(RegistrationInteractorTests.StubError.any)
    var loginResult: Result<LoginResponseDTO, Error> = .failure(RegistrationInteractorTests.StubError.any)

    private(set) var startRegistrationRequests: [RegisterRequestDTO] = []

    func startEmailRegistration(_ request: RegisterRequestDTO) async throws -> EmailVerificationChallengeResponseDTO {
        startRegistrationRequests.append(request)

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
private final class RegistrationPresenterSpy: RegistrationPresentationLogic, @unchecked Sendable {
    private(set) var presentedData: [RegistrationFetchData] = []

    func presentFetchedData(_ data: RegistrationFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class RegistrationRouterSpy: RegistrationRoutingLogic, @unchecked Sendable {
    private(set) var presentedErrors: [String] = []
    private(set) var emailVerificationContexts: [EmailVerificationContext] = []

    func openEmailVerification(
        context: EmailVerificationContext,
        registrationStorage: RegistrationStorageProtocol
    ) {
        emailVerificationContexts.append(context)
    }

    func presentError(with text: String) {
        presentedErrors.append(text)
    }
}

private struct CurrencyProviderStub: RegistrationCurrencyProviding {
    func fiatCurrencies() -> [RegistrationCurrency] {
        [
            .init(code: "USD", title: "US Dollar"),
            .init(code: "RUB", title: "Russian Ruble"),
            .init(code: "KZT", title: "Kazakhstani Tenge"),
            .init(code: "EUR", title: "Euro")
        ]
    }
}

private struct LocaleProviderStub: RegistrationLocaleProviding {
    let preferredLanguageIdentifier: String = "en-US"
    let preferredCurrencyCode: String = "USD"
}
