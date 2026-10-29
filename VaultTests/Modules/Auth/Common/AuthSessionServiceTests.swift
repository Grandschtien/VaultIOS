import XCTest
import Foundation
import NetworkClient
@testable import Vylok

final class AuthSessionServiceTests: XCTestCase {
    private var networkClient: AsyncNetworkClientMock!
    private var tokenStorage: TokenStorageServiceProtocolMock!
    private var profileStorage: UserProfileStorageServiceProtocolMock!

    override func setUp() {
        super.setUp()
        networkClient = AsyncNetworkClientMock()
        tokenStorage = TokenStorageServiceProtocolMock()
        profileStorage = UserProfileStorageServiceProtocolMock()
    }

    override func tearDown() {
        profileStorage = nil
        tokenStorage = nil
        networkClient = nil
        super.tearDown()
    }
}

// MARK: - hasValidSession

extension AuthSessionServiceTests {
    func testHasValidSessionWhenTokenIsNotExpiredReturnsTrueWithoutRefresh() async {
        // Arrange
        let sut = AuthSessionService(
            networkClient: networkClient,
            tokenStorageService: tokenStorage,
            userProfileStorageService: profileStorage
        )
        tokenStorage.getTokenReturnValue = AuthTokenDTO(
            accessToken: "access",
            refreshToken: "refresh",
            tokenType: "bearer",
            expiresIn: 900,
            issuedAt: Date().timeIntervalSince1970 - 10
        )

        // Act
        let hasValidSession = await sut.hasValidSession()

        // Assert
        XCTAssertTrue(hasValidSession)
        XCTAssertTrue(networkClient.capturedTargets.isEmpty)
    }

    func testHasValidSessionWhenTokenExpiredAndRefreshSucceedsReturnsTrueAndPersistsToken() async throws {
        // Arrange
        let sut = AuthSessionService(
            networkClient: networkClient,
            tokenStorageService: tokenStorage,
            userProfileStorageService: profileStorage
        )
        tokenStorage.getTokenReturnValue = AuthTokenDTO(
            accessToken: "old-access",
            refreshToken: "old-refresh",
            tokenType: "bearer",
            expiresIn: 900,
            issuedAt: Date().timeIntervalSince1970 - 901
        )
        networkClient.setResponse(
            json: #"{"access_token":"new-access","refresh_token":"new-refresh","token_type":"bearer","expires_in":900}"#
        )

        // Act
        let hasValidSession = await sut.hasValidSession()

        // Assert
        let storedToken = try XCTUnwrap(tokenStorage.setTokenReceivedArguments)
        let issuedAt = try XCTUnwrap(storedToken.issuedAt)
        XCTAssertTrue(hasValidSession)
        XCTAssertEqual(networkClient.capturedTargets.count, 1)
        XCTAssertEqual(tokenStorage.setTokenCallsCount, 1)
        XCTAssertEqual(
            storedToken,
            AuthTokenDTO(
                accessToken: "new-access",
                refreshToken: "new-refresh",
                tokenType: "bearer",
                expiresIn: 900,
                issuedAt: issuedAt
            )
        )
    }

    func testHasValidSessionWhenRefreshFailsClearsSessionAndReturnsFalse() async {
        // Arrange
        let sut = AuthSessionService(
            networkClient: networkClient,
            tokenStorageService: tokenStorage,
            userProfileStorageService: profileStorage
        )
        tokenStorage.getTokenReturnValue = AuthTokenDTO(
            accessToken: "old-access",
            refreshToken: "old-refresh",
            tokenType: "bearer",
            expiresIn: 900,
            issuedAt: Date().timeIntervalSince1970 - 901
        )
        networkClient.nextError = TestError.any
        let logoutExpectation = expectation(forNotification: .authSessionDidLogout, object: nil)

        // Act
        let hasValidSession = await sut.hasValidSession()

        // Assert
        await fulfillment(of: [logoutExpectation], timeout: 1.0)
        XCTAssertFalse(hasValidSession)
        XCTAssertEqual(networkClient.capturedTargets.count, 1)
        XCTAssertEqual(tokenStorage.removeTokenCallsCount, 1)
        XCTAssertEqual(profileStorage.clearProfileCallsCount, 1)
    }

    func testHasValidSessionWhenTokenIsMissingReturnsFalse() async {
        // Arrange
        let sut = AuthSessionService(
            networkClient: networkClient,
            tokenStorageService: tokenStorage,
            userProfileStorageService: profileStorage
        )

        // Act
        let hasValidSession = await sut.hasValidSession()

        // Assert
        XCTAssertFalse(hasValidSession)
        XCTAssertTrue(networkClient.capturedTargets.isEmpty)
    }
}

// MARK: - refreshAccessToken

extension AuthSessionServiceTests {
    func testRefreshAccessTokenWhenCalledConcurrentlySendsSingleRefreshRequest() async throws {
        // Arrange
        let sut = AuthSessionService(
            networkClient: networkClient,
            tokenStorageService: tokenStorage,
            userProfileStorageService: profileStorage
        )
        tokenStorage.getTokenReturnValue = AuthTokenDTO(
            accessToken: "old-access",
            refreshToken: "old-refresh",
            tokenType: "bearer",
            expiresIn: 900,
            issuedAt: Date().timeIntervalSince1970 - 901
        )
        networkClient.setResponse(
            json: #"{"access_token":"new-access","refresh_token":"new-refresh","token_type":"bearer","expires_in":900}"#
        )
        networkClient.responseDelayNanoseconds = 100_000_000

        // Act
        async let firstToken = sut.refreshAccessToken()
        async let secondToken = sut.refreshAccessToken()
        let tokens = try await [firstToken, secondToken]

        // Assert
        XCTAssertEqual(tokens.map(\.accessToken), ["new-access", "new-access"])
        XCTAssertEqual(networkClient.capturedTargets.count, 1)
    }
}

// MARK: - logout

extension AuthSessionServiceTests {
    func testLogoutClearsTokenAndProfileAndPostsNotification() async {
        // Arrange
        let sut = AuthSessionService(
            networkClient: networkClient,
            tokenStorageService: tokenStorage,
            userProfileStorageService: profileStorage
        )
        let logoutExpectation = expectation(forNotification: .authSessionDidLogout, object: nil)

        // Act
        await sut.logout()

        // Assert
        await fulfillment(of: [logoutExpectation], timeout: 1.0)
        XCTAssertEqual(tokenStorage.removeTokenCallsCount, 1)
        XCTAssertEqual(profileStorage.clearProfileCallsCount, 1)
    }
}

// MARK: - logoutFromBackend

extension AuthSessionServiceTests {
    func testLogoutFromBackendWhenRequestSucceedsLogsOutLocally() async throws {
        // Arrange
        let sut = AuthSessionService(
            networkClient: networkClient,
            tokenStorageService: tokenStorage,
            userProfileStorageService: profileStorage
        )
        tokenStorage.getTokenReturnValue = AuthTokenDTO(
            accessToken: "access",
            refreshToken: "refresh",
            tokenType: "bearer",
            expiresIn: 900,
            issuedAt: Date().timeIntervalSince1970
        )
        let logoutExpectation = expectation(forNotification: .authSessionDidLogout, object: nil)

        // Act
        try await sut.logoutFromBackend()

        // Assert
        await fulfillment(of: [logoutExpectation], timeout: 1.0)
        XCTAssertEqual(networkClient.capturedTargets.count, 1)
        XCTAssertEqual(tokenStorage.removeTokenCallsCount, 1)
        XCTAssertEqual(profileStorage.clearProfileCallsCount, 1)
    }

    func testLogoutFromBackendWhenRequestFailsThrowsAndKeepsSession() async {
        // Arrange
        let sut = AuthSessionService(
            networkClient: networkClient,
            tokenStorageService: tokenStorage,
            userProfileStorageService: profileStorage
        )
        tokenStorage.getTokenReturnValue = AuthTokenDTO(
            accessToken: "access",
            refreshToken: "refresh",
            tokenType: "bearer",
            expiresIn: 900,
            issuedAt: Date().timeIntervalSince1970
        )
        networkClient.nextError = TestError.any
        let logoutExpectation = expectation(forNotification: .authSessionDidLogout, object: nil)
        logoutExpectation.isInverted = true

        // Act
        let result = await Result { try await sut.logoutFromBackend() }

        // Assert
        await fulfillment(of: [logoutExpectation], timeout: 0.1)
        XCTAssertEqual(result.failure as? TestError, .any)
        XCTAssertEqual(networkClient.capturedTargets.count, 1)
        XCTAssertFalse(tokenStorage.removeTokenCalled)
        XCTAssertFalse(profileStorage.clearProfileCalled)
    }
}
