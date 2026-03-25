import XCTest
import Foundation
import NetworkClient
@testable import Vault

@MainActor
final class RegistrationInteractorTests: XCTestCase {
    func testRegistrationHappyPathSavesTokenAndClearsStorage() async {
        let networkClient = AsyncNetworkClientSpy()
        networkClient.nextResult = .success(
            LoginResponseDTO(
                accessToken: "access",
                refreshToken: "refresh",
                tokenType: "bearer",
                expiresIn: 3600,
                user: .init(
                    id: "1",
                    email: "name@example.com",
                    name: "Egor",
                    currency: "USD",
                    preferredLanguage: "en-US",
                    tier: "free"
                )
            )
        )

        let presenter = RegistrationPresenterSpy()
        let router = RegistrationRouterSpy()
        let tokenStorage = TokenStorageSpy()
        let profileStorage = UserProfileStorageSpy()
        let storage = RegistrationStorage()
        let sut = makeSut(
            networkClient: networkClient,
            presenter: presenter,
            router: router,
            tokenStorage: tokenStorage,
            profileStorage: profileStorage,
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

        XCTAssertEqual(networkClient.registerRequest?.provider, "password")
        XCTAssertEqual(networkClient.registerRequest?.email, "name@example.com")
        XCTAssertEqual(networkClient.registerRequest?.name, "Egor")
        XCTAssertEqual(networkClient.registerRequest?.currency, "USD")
        XCTAssertEqual(networkClient.registerRequest?.preferredLanguage, "en-US")

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

        let draft = await storage.loadDraft()
        XCTAssertEqual(draft, .init())

        guard let lastPresentedData = presenter.presentedData.last else {
            return XCTFail("Expected presenter to receive data")
        }

        if case .loaded = lastPresentedData.loadingState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected loading state to be loaded")
        }

        XCTAssertTrue(router.presentedErrors.isEmpty)
        XCTAssertEqual(router.openedMainFlowCount, 1)
    }
}

extension RegistrationInteractorTests {
    func testSecondaryButtonMovesBackKeepingEnteredValues() async {
        let networkClient = AsyncNetworkClientSpy()
        let presenter = RegistrationPresenterSpy()
        let router = RegistrationRouterSpy()
        let tokenStorage = TokenStorageSpy()
        let storage = RegistrationStorage()
        let sut = makeSut(
            networkClient: networkClient,
            presenter: presenter,
            router: router,
            tokenStorage: tokenStorage,
            profileStorage: UserProfileStorageSpy(),
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
}

extension RegistrationInteractorTests {
    func testPrimaryButtonBlocksStepOneOnInvalidEmail() async {
        let presenter = RegistrationPresenterSpy()
        let sut = makeSut(
            networkClient: AsyncNetworkClientSpy(),
            presenter: presenter,
            router: RegistrationRouterSpy(),
            tokenStorage: TokenStorageSpy(),
            profileStorage: UserProfileStorageSpy(),
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
}

extension RegistrationInteractorTests {
    func testRegistrationFailurePresentsRouterError() async {
        let networkClient = AsyncNetworkClientSpy()
        networkClient.nextResult = .failure(StubError.any)
        let presenter = RegistrationPresenterSpy()
        let router = RegistrationRouterSpy()
        let profileStorage = UserProfileStorageSpy()
        let sut = makeSut(
            networkClient: networkClient,
            presenter: presenter,
            router: router,
            tokenStorage: TokenStorageSpy(),
            profileStorage: profileStorage,
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
        guard let lastData = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        if case .failed = lastData.loadingState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected failed loading state")
        }
        XCTAssertEqual(router.openedMainFlowCount, 0)
        XCTAssertNil(profileStorage.savedProfile)
    }
}

extension RegistrationInteractorTests {
    func testHandleFlowDidExitClearsStorage() async {
        let storage = RegistrationStorage()
        let sut = makeSut(
            networkClient: AsyncNetworkClientSpy(),
            presenter: RegistrationPresenterSpy(),
            router: RegistrationRouterSpy(),
            tokenStorage: TokenStorageSpy(),
            profileStorage: UserProfileStorageSpy(),
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
        networkClient: AsyncNetworkClient,
        presenter: RegistrationPresentationLogic,
        router: RegistrationRoutingLogic,
        tokenStorage: TokenStorageServiceProtocol,
        profileStorage: UserProfileStorageServiceProtocol,
        storage: RegistrationStorageProtocol
    ) -> RegistrationInteractor {
        RegistrationInteractor(
            networkClient: networkClient,
            presenter: presenter,
            router: router,
            tokenStorageService: tokenStorage,
            userProfileStorageService: profileStorage,
            registrationStorage: storage,
            currencyProvider: CurrencyProviderStub(),
            localeProvider: LocaleProviderStub()
        )
    }

    enum StubError: Error {
        case any
    }
}

private final class AsyncNetworkClientSpy: AsyncNetworkClient {
    var nextResult: Result<LoginResponseDTO, Error> = .failure(RegistrationInteractorTests.StubError.any)
    private(set) var registerRequest: RegisterRequestDTO?

    func request<T: Codable, InBodyError: CustomError>(
        inBodyError: InBodyError.Type,
        _ target: ApiTarget,
        responseType: T.Type,
        decoder: JSONDecoder
    ) async throws -> T {
        if let authTarget = target as? AuthAPI,
           case let .register(dto) = authTarget {
            registerRequest = dto
        }

        switch nextResult {
        case let .success(response):
            guard let typedResponse = response as? T else {
                throw RegistrationInteractorTests.StubError.any
            }

            return typedResponse

        case let .failure(error):
            throw error
        }
    }

    func request<InBodyError: CustomError>(
        inBodyError: InBodyError.Type,
        _ target: ApiTarget
    ) async throws {}
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
    private(set) var openedMainFlowCount: Int = .zero

    func openMainFlow() {
        openedMainFlowCount += 1
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
