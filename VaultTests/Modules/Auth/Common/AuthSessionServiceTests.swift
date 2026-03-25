import XCTest
import Foundation
import NetworkClient
@testable import Vault

final class AuthSessionServiceTests: XCTestCase {
    func testHasValidSessionWhenTokenIsNotExpiredReturnsTrueWithoutRefresh() async {
        let networkClient = AsyncNetworkClientSpy()
        let tokenStorage = TokenStorageSpy()
        let profileStorage = UserProfileStorageSpy()
        tokenStorage.setToken(
            AuthTokenDTO(
                accessToken: "access",
                refreshToken: "refresh",
                tokenType: "bearer",
                expiresIn: 900,
                issuedAt: Date().timeIntervalSince1970 - 10
            )
        )
        let sut = makeSut(
            networkClient: networkClient,
            tokenStorage: tokenStorage,
            profileStorage: profileStorage
        )

        let hasValidSession = await sut.hasValidSession()

        XCTAssertTrue(hasValidSession)
        XCTAssertEqual(networkClient.refreshRequestCount, 0)
    }
}

extension AuthSessionServiceTests {
    func testHasValidSessionWhenTokenExpiredAndRefreshSucceedsReturnsTrueAndPersistsToken() async {
        let networkClient = AsyncNetworkClientSpy()
        networkClient.refreshResult = .success(
            AuthTokenDTO(
                accessToken: "new-access",
                refreshToken: "new-refresh",
                tokenType: "bearer",
                expiresIn: 900
            )
        )
        let tokenStorage = TokenStorageSpy()
        let profileStorage = UserProfileStorageSpy()
        tokenStorage.setToken(
            AuthTokenDTO(
                accessToken: "old-access",
                refreshToken: "old-refresh",
                tokenType: "bearer",
                expiresIn: 900,
                issuedAt: Date().timeIntervalSince1970 - 901
            )
        )
        let sut = makeSut(
            networkClient: networkClient,
            tokenStorage: tokenStorage,
            profileStorage: profileStorage
        )

        let hasValidSession = await sut.hasValidSession()

        XCTAssertTrue(hasValidSession)
        XCTAssertEqual(networkClient.refreshRequestCount, 1)
        XCTAssertEqual(tokenStorage.getToken()?.accessToken, "new-access")
        XCTAssertEqual(tokenStorage.getToken()?.refreshToken, "new-refresh")
        XCTAssertEqual(tokenStorage.getToken()?.expiresIn, 900)
        XCTAssertNotNil(tokenStorage.getToken()?.issuedAt)
    }
}

extension AuthSessionServiceTests {
    func testHasValidSessionWhenRefreshFailsRemovesTokenAndReturnsFalse() async {
        let networkClient = AsyncNetworkClientSpy()
        networkClient.refreshResult = .failure(StubError.any)
        let tokenStorage = TokenStorageSpy()
        let profileStorage = UserProfileStorageSpy()
        tokenStorage.setToken(
            AuthTokenDTO(
                accessToken: "old-access",
                refreshToken: "old-refresh",
                tokenType: "bearer",
                expiresIn: 900,
                issuedAt: Date().timeIntervalSince1970 - 901
            )
        )
        profileStorage.saveProfile(
            UserProfileDefaults(
                userId: "1",
                email: "name@example.com",
                name: "Egor",
                currency: "USD",
                language: "en-US"
            )
        )
        let sut = makeSut(
            networkClient: networkClient,
            tokenStorage: tokenStorage,
            profileStorage: profileStorage
        )
        let logoutExpectation = expectation(
            forNotification: .authSessionDidLogout,
            object: nil
        )

        let hasValidSession = await sut.hasValidSession()

        XCTAssertFalse(hasValidSession)
        XCTAssertNil(tokenStorage.getToken())
        XCTAssertNil(profileStorage.loadProfile())
        XCTAssertEqual(networkClient.refreshRequestCount, 1)
        await fulfillment(of: [logoutExpectation], timeout: 1.0)
    }
}

extension AuthSessionServiceTests {
    func testHasValidSessionWhenTokenIsMissingReturnsFalse() async {
        let networkClient = AsyncNetworkClientSpy()
        let tokenStorage = TokenStorageSpy()
        let sut = makeSut(
            networkClient: networkClient,
            tokenStorage: tokenStorage,
            profileStorage: UserProfileStorageSpy()
        )

        let hasValidSession = await sut.hasValidSession()

        XCTAssertFalse(hasValidSession)
        XCTAssertEqual(networkClient.refreshRequestCount, 0)
    }
}

extension AuthSessionServiceTests {
    func testRefreshAccessTokenConcurrentCallsUsesSingleRefreshRequest() async throws {
        let networkClient = AsyncNetworkClientSpy()
        networkClient.refreshResult = .success(
            AuthTokenDTO(
                accessToken: "new-access",
                refreshToken: "new-refresh",
                tokenType: "bearer",
                expiresIn: 900
            )
        )
        networkClient.refreshDelayNanoseconds = 100_000_000
        let tokenStorage = TokenStorageSpy()
        let profileStorage = UserProfileStorageSpy()
        tokenStorage.setToken(
            AuthTokenDTO(
                accessToken: "old-access",
                refreshToken: "old-refresh",
                tokenType: "bearer",
                expiresIn: 900,
                issuedAt: Date().timeIntervalSince1970 - 901
            )
        )
        let sut = makeSut(
            networkClient: networkClient,
            tokenStorage: tokenStorage,
            profileStorage: profileStorage
        )

        async let firstToken = sut.refreshAccessToken()
        async let secondToken = sut.refreshAccessToken()

        let first = try await firstToken
        let second = try await secondToken

        XCTAssertEqual(first.accessToken, "new-access")
        XCTAssertEqual(second.accessToken, "new-access")
        XCTAssertEqual(networkClient.refreshRequestCount, 1)
    }
}

extension AuthSessionServiceTests {
    func testLogoutClearsTokenAndProfileAndPostsNotification() async {
        let networkClient = AsyncNetworkClientSpy()
        let tokenStorage = TokenStorageSpy()
        let profileStorage = UserProfileStorageSpy()
        tokenStorage.setToken(
            AuthTokenDTO(
                accessToken: "access",
                refreshToken: "refresh",
                tokenType: "bearer",
                expiresIn: 900,
                issuedAt: Date().timeIntervalSince1970
            )
        )
        profileStorage.saveProfile(
            UserProfileDefaults(
                userId: "1",
                email: "name@example.com",
                name: "Egor",
                currency: "USD",
                language: "en-US"
            )
        )
        let sut = makeSut(
            networkClient: networkClient,
            tokenStorage: tokenStorage,
            profileStorage: profileStorage
        )
        let logoutExpectation = expectation(
            forNotification: .authSessionDidLogout,
            object: nil
        )

        await sut.logout()

        XCTAssertNil(tokenStorage.getToken())
        XCTAssertNil(profileStorage.loadProfile())
        await fulfillment(of: [logoutExpectation], timeout: 1.0)
    }
}

private extension AuthSessionServiceTests {
    func makeSut(
        networkClient: AsyncNetworkClient,
        tokenStorage: TokenStorageServiceProtocol,
        profileStorage: UserProfileStorageServiceProtocol
    ) -> AuthSessionService {
        AuthSessionService(
            networkClient: networkClient,
            tokenStorageService: tokenStorage,
            userProfileStorageService: profileStorage
        )
    }

    enum StubError: Error {
        case any
    }
}

private final class TokenStorageSpy: TokenStorageServiceProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var token: AuthTokenDTO?

    func setToken(_ token: AuthTokenDTO) {
        lock.withLock {
            self.token = token
        }
    }

    func getToken() -> AuthTokenDTO? {
        lock.withLock { token }
    }

    func removeToken() {
        lock.withLock {
            token = nil
        }
    }
}

private final class UserProfileStorageSpy: UserProfileStorageServiceProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var profile: UserProfileDefaults?

    func saveProfile(_ profile: UserProfileDefaults) {
        lock.withLock {
            self.profile = profile
        }
    }

    func loadProfile() -> UserProfileDefaults? {
        lock.withLock { profile }
    }

    func clearProfile() {
        lock.withLock {
            profile = nil
        }
    }
}

private final class AsyncNetworkClientSpy: AsyncNetworkClient, @unchecked Sendable {
    var refreshResult: Result<AuthTokenDTO, Error> = .failure(AuthSessionServiceTests.StubError.any)
    var refreshDelayNanoseconds: UInt64 = .zero
    private(set) var refreshRequestCount: Int = .zero
    private let lock = NSLock()

    func request<T: Codable, InBodyError: CustomError>(
        inBodyError: InBodyError.Type,
        _ target: ApiTarget,
        responseType: T.Type,
        decoder: JSONDecoder
    ) async throws -> T {
        guard let authTarget = target as? AuthAPI, case .refresh = authTarget else {
            throw AuthSessionServiceTests.StubError.any
        }

        if refreshDelayNanoseconds > .zero {
            try await Task.sleep(nanoseconds: refreshDelayNanoseconds)
        }

        lock.withLock {
            refreshRequestCount += 1
        }

        switch refreshResult {
        case let .success(token):
            guard let response = token as? T else {
                throw AuthSessionServiceTests.StubError.any
            }

            return response

        case let .failure(error):
            throw error
        }
    }

    func request<InBodyError: CustomError>(
        inBodyError: InBodyError.Type,
        _ target: ApiTarget
    ) async throws {}
}

private extension NSLock {
    func withLock<T>(_ block: () -> T) -> T {
        lock()
        defer { unlock() }
        return block()
    }
}
