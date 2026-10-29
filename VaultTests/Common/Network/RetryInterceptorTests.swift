import XCTest
import Foundation
import Alamofire
@testable import Vylok

final class RetryInterceptorTests: XCTestCase {
    private var authSessionService: AuthSessionServiceProtocolMock!

    override func setUp() {
        super.setUp()
        authSessionService = AuthSessionServiceProtocolMock()
    }

    override func tearDown() {
        authSessionService = nil
        super.tearDown()
    }
}

// MARK: - retry

extension RetryInterceptorTests {
    func testRetryWhenUnauthorizedAndRefreshSucceedsReturnsRetry() async {
        // Arrange
        let sut = RetryInterceptor(authSessionService: authSessionService)
        authSessionService.refreshAccessTokenReturnValue = AuthTokenDTO(
            accessToken: "new-access",
            refreshToken: "new-refresh",
            tokenType: "bearer",
            expiresIn: 900
        )

        // Act
        let retryResult = await resolveRetryResult(sut: sut, statusCode: 401, path: "/expenses", retryCount: 0)

        // Assert
        guard case .retry = retryResult else {
            return XCTFail("Expected retry, got \(retryResult)")
        }
        XCTAssertEqual(authSessionService.refreshAccessTokenCallsCount, 1)
    }

    func testRetryWhenUnauthorizedAndRefreshFailsDoesNotRetryWithRefreshError() async {
        // Arrange
        let sut = RetryInterceptor(authSessionService: authSessionService)
        authSessionService.refreshAccessTokenThrowableError = TestError.any

        // Act
        let retryResult = await resolveRetryResult(sut: sut, statusCode: 401, path: "/expenses", retryCount: 0)

        // Assert
        guard case let .doNotRetryWithError(error) = retryResult else {
            return XCTFail("Expected doNotRetryWithError, got \(retryResult)")
        }
        XCTAssertEqual(error as? TestError, .any)
        XCTAssertEqual(authSessionService.refreshAccessTokenCallsCount, 1)
    }

    func testRetryWhenRequestWasAlreadyRetriedDoesNotRetryWithOriginalError() async {
        // Arrange
        let sut = RetryInterceptor(authSessionService: authSessionService)

        // Act
        let retryResult = await resolveRetryResult(sut: sut, statusCode: 401, path: "/expenses", retryCount: 1)

        // Assert
        guard case let .doNotRetryWithError(error) = retryResult else {
            return XCTFail("Expected doNotRetryWithError, got \(retryResult)")
        }
        XCTAssertEqual(error as? TestError, .any)
        XCTAssertFalse(authSessionService.refreshAccessTokenCalled)
    }

    func testRetryWhenUnauthorizedForLogoutPathDoesNotRetry() async {
        // Arrange
        let sut = RetryInterceptor(authSessionService: authSessionService)

        // Act
        let retryResult = await resolveRetryResult(sut: sut, statusCode: 401, path: "/auth/logout", retryCount: 0)

        // Assert
        guard case .doNotRetry = retryResult else {
            return XCTFail("Expected doNotRetry, got \(retryResult)")
        }
        XCTAssertFalse(authSessionService.refreshAccessTokenCalled)
    }

    func testRetryWhenStatusCodeIsNotUnauthorizedDoesNotRetry() async {
        // Arrange
        let sut = RetryInterceptor(authSessionService: authSessionService)

        // Act
        let retryResult = await resolveRetryResult(sut: sut, statusCode: 403, path: "/expenses", retryCount: 0)

        // Assert
        guard case .doNotRetry = retryResult else {
            return XCTFail("Expected doNotRetry, got \(retryResult)")
        }
        XCTAssertFalse(authSessionService.refreshAccessTokenCalled)
    }
}

private extension RetryInterceptorTests {
    func resolveRetryResult(
        sut: RetryInterceptor,
        statusCode: Int?,
        path: String?,
        retryCount: Int
    ) async -> RetryResult {
        await withCheckedContinuation { continuation in
            sut.retry(statusCode: statusCode, path: path, retryCount: retryCount, dueTo: TestError.any) { retryResult in
                continuation.resume(returning: retryResult)
            }
        }
    }
}
