import XCTest
import Foundation
import NetworkClient
@testable import Vault

@MainActor
final class LoginInteractorTests: XCTestCase {
    func testSignInHappyPathStoresTokenAndOpensMainFlow() async {
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

        let presenter = LoginPresenterSpy()
        let router = LoginRouterSpy()
        let tokenStorage = TokenStorageSpy()
        let sut = makeSut(
            networkClient: networkClient,
            presenter: presenter,
            router: router,
            tokenStorage: tokenStorage
        )

        await sut.handleEmailDidChange("name@example.com")
        await sut.handlePasswordDidChange("12345678")
        await sut.handleSignInDidTap()

        XCTAssertEqual(networkClient.loginRequest?.provider.rawValue, LoginRequestDTO.LoginProvider.password.rawValue)
        XCTAssertEqual(networkClient.loginRequest?.email, "name@example.com")
        XCTAssertEqual(networkClient.loginRequest?.password, "12345678")
        XCTAssertEqual(
            tokenStorage.savedToken,
            AuthTokenDTO(
                accessToken: "access",
                refreshToken: "refresh",
                tokenType: "bearer",
                expiresIn: 3600
            )
        )
        XCTAssertEqual(router.openedMainFlowCount, 1)
        XCTAssertTrue(router.presentedErrors.isEmpty)

        guard let lastData = presenter.presentedData.last else {
            return XCTFail("Expected presenter update")
        }

        if case .loaded = lastData.loadingState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected loaded state")
        }
    }
}

extension LoginInteractorTests {
    func testSignInWithEmptyEmailDoesNotOpenMainFlow() async {
        let presenter = LoginPresenterSpy()
        let router = LoginRouterSpy()
        let sut = makeSut(
            networkClient: AsyncNetworkClientSpy(),
            presenter: presenter,
            router: router,
            tokenStorage: TokenStorageSpy()
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

        guard let localError = error as? LoginInteractor.LocalError else {
            return XCTFail("Expected local validation error")
        }

        switch localError {
        case .emptyEmail:
            XCTAssertTrue(true)
        case .emptyPassword:
            XCTFail("Expected emptyEmail error")
        }
    }
}

extension LoginInteractorTests {
    func testSignInFailurePresentsErrorAndDoesNotOpenMainFlow() async {
        let networkClient = AsyncNetworkClientSpy()
        networkClient.nextResult = .failure(StubError.any)
        let presenter = LoginPresenterSpy()
        let router = LoginRouterSpy()
        let sut = makeSut(
            networkClient: networkClient,
            presenter: presenter,
            router: router,
            tokenStorage: TokenStorageSpy()
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
    }
}

private extension LoginInteractorTests {
    func makeSut(
        networkClient: AsyncNetworkClient,
        presenter: LoginPresentationLogic,
        router: LoginRoutingLogic,
        tokenStorage: TokenStorageServiceProtocol
    ) -> LoginInteractor {
        LoginInteractor(
            networkClient: networkClient,
            presenter: presenter,
            router: router,
            tokenStorageService: tokenStorage
        )
    }

    enum StubError: Error {
        case any
    }
}

private final class AsyncNetworkClientSpy: AsyncNetworkClient {
    var nextResult: Result<LoginResponseDTO, Error> = .failure(LoginInteractorTests.StubError.any)
    private(set) var loginRequest: LoginRequestDTO?

    func request<T: Codable, InBodyError: CustomError>(
        inBodyError: InBodyError.Type,
        _ target: ApiTarget,
        responseType: T.Type,
        decoder: JSONDecoder
    ) async throws -> T {
        if let authTarget = target as? AuthAPI,
           case let .login(dto) = authTarget {
            loginRequest = dto
        }

        switch nextResult {
        case let .success(response):
            guard let typedResponse = response as? T else {
                throw LoginInteractorTests.StubError.any
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

    func openRegistration() {}

    func openMainFlow() {
        openedMainFlowCount += 1
    }

    func openForgetPasswordScreen() {}

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
