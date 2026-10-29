import XCTest
@testable import Vylok

@MainActor
final class RegistrationInteractorTests: XCTestCase {
    private var authVerificationService: AuthVerificationContractServicingMock!
    private var presenter: RegistrationPresentationLogicMock!
    private var router: RegistrationRoutingLogicMock!
    private var currencyProvider: RegistrationCurrencyProvidingMock!
    private var localeProvider: RegistrationLocaleProvidingMock!

    override func setUp() {
        super.setUp()
        authVerificationService = AuthVerificationContractServicingMock()
        presenter = RegistrationPresentationLogicMock()
        router = RegistrationRoutingLogicMock()
        currencyProvider = RegistrationCurrencyProvidingMock()
        currencyProvider.fiatCurrenciesReturnValue = [
            .init(code: "USD", title: "US Dollar"),
            .init(code: "RUB", title: "Russian Ruble"),
            .init(code: "KZT", title: "Kazakhstani Tenge"),
            .init(code: "EUR", title: "Euro")
        ]
        localeProvider = RegistrationLocaleProvidingMock()
        localeProvider.preferredLanguageIdentifier = "en-US"
        localeProvider.preferredCurrencyCode = "USD"
    }

    override func tearDown() {
        localeProvider = nil
        currencyProvider = nil
        router = nil
        presenter = nil
        authVerificationService = nil
        super.tearDown()
    }
}

// MARK: - Registration flow

extension RegistrationInteractorTests {
    func testRegistrationHappyPathOpensEmailVerificationAndKeepsDraft() async {
        authVerificationService.startEmailRegistrationReturnValue = EmailVerificationChallengeResponseDTO(
            status: "code_sent",
            email: "name@example.com",
            expiresIn: 600,
            resendAvailableIn: 60
        )

        let storage = RegistrationStorage()
        let sut = RegistrationInteractor(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            registrationStorage: storage,
            currencyProvider: currencyProvider,
            localeProvider: localeProvider
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
            authVerificationService.startEmailRegistrationReceivedInvocations,
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

        XCTAssertTrue(router.presentErrorWithReceivedInvocations.isEmpty)
        XCTAssertEqual(
            router.openEmailVerificationContextRegistrationStorageReceivedInvocations.map(\.context),
            [
                EmailVerificationContext(
                    source: .registration,
                    email: "name@example.com",
                    expiresIn: 600,
                    resendAvailableIn: 60
                )
            ]
        )

        guard let lastPresentedData = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter to receive data")
        }

        if case .loaded = lastPresentedData.loadingState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected loading state to be loaded")
        }
    }

    func testSecondaryButtonMovesBackKeepingEnteredValues() async {
        let storage = RegistrationStorage()
        let sut = RegistrationInteractor(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            registrationStorage: storage,
            currencyProvider: currencyProvider,
            localeProvider: localeProvider
        )

        await sut.fetchData()
        await sut.handleEmailDidChange("name@example.com")
        await sut.handlePasswordDidChange("12345678")
        await sut.handleConfirmPasswordDidChange("12345678")
        await sut.handleTapPrimaryButton()
        await sut.handleNameDidChange("Egor")
        await sut.handleTapPrimaryButton()

        await sut.handleTapSecondaryButton()

        guard let afterFirstBack = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter update after first back")
        }

        XCTAssertEqual(afterFirstBack.step, .name)
        XCTAssertEqual(afterFirstBack.name, "Egor")

        await sut.handleTapSecondaryButton()

        guard let afterSecondBack = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter update after second back")
        }

        XCTAssertEqual(afterSecondBack.step, .account)
        XCTAssertEqual(afterSecondBack.email, "name@example.com")
    }

    func testPrimaryButtonBlocksStepOneOnInvalidEmail() async {
        let sut = RegistrationInteractor(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            registrationStorage: RegistrationStorage(),
            currencyProvider: currencyProvider,
            localeProvider: localeProvider
        )

        await sut.fetchData()
        await sut.handleEmailDidChange("invalid")
        await sut.handlePasswordDidChange("12345678")
        await sut.handleConfirmPasswordDidChange("12345678")
        await sut.handleTapPrimaryButton()

        guard let lastData = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter update")
        }

        XCTAssertEqual(lastData.step, .account)
        XCTAssertEqual(lastData.emailErrorMessage, L10n.registrationErrorInvalidEmail)
    }

    func testPrimaryButtonBlocksStepOneOnShortPassword() async {
        let sut = RegistrationInteractor(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            registrationStorage: RegistrationStorage(),
            currencyProvider: currencyProvider,
            localeProvider: localeProvider
        )

        await sut.fetchData()
        await sut.handleEmailDidChange("name@example.com")
        await sut.handlePasswordDidChange("1234567")
        await sut.handleConfirmPasswordDidChange("1234567")
        await sut.handleTapPrimaryButton()

        guard let lastData = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter update")
        }

        XCTAssertEqual(lastData.step, .account)
        XCTAssertEqual(lastData.passwordErrorMessage, L10n.registrationErrorPasswordTooShort)
    }

    func testRegistrationFailurePresentsRouterError() async {
        authVerificationService.startEmailRegistrationThrowableError = TestError.any
        let sut = RegistrationInteractor(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            registrationStorage: RegistrationStorage(),
            currencyProvider: currencyProvider,
            localeProvider: localeProvider
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

        XCTAssertEqual(router.presentErrorWithReceivedInvocations.count, 1)
        XCTAssertTrue(router.openEmailVerificationContextRegistrationStorageReceivedInvocations.map(\.context).isEmpty)

        guard let lastData = presenter.presentFetchedDataReceivedInvocations.last else {
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
        let sut = RegistrationInteractor(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            registrationStorage: storage,
            currencyProvider: currencyProvider,
            localeProvider: localeProvider
        )

        await sut.fetchData()
        await sut.handleEmailDidChange("name@example.com")

        await sut.handleFlowDidExit()

        let draft = await storage.loadDraft()
        XCTAssertEqual(draft, .init())
    }
}
