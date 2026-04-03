import XCTest
import Foundation
import Alamofire
@testable import Vault

final class RetryInterceptorTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocolStub.responseStatusCode = 200
    }
}

extension RetryInterceptorTests {
    func testRetryWhenUnauthorizedAndRefreshSucceedsReturnsRetry() async {
        let authSessionService = AuthSessionServiceStub(
            refreshResult: .success(
                AuthTokenDTO(
                    accessToken: "new-access",
                    refreshToken: "new-refresh",
                    tokenType: "bearer",
                    expiresIn: 900
                )
            )
        )
        let sut = RetryInterceptor(authSessionService: authSessionService)
        let (session, request) = await makeCompletedRequest(
            statusCode: 401,
            path: "/expenses"
        )

        let retryResult = await resolveRetryResult(
            sut: sut,
            request: request,
            session: session
        )

        switch retryResult {
        case .retry:
            let refreshCallCount = await authSessionService.currentRefreshCallCount()
            XCTAssertEqual(refreshCallCount, 1)
        default:
            XCTFail("Expected retry")
        }
    }
}

extension RetryInterceptorTests {
    func testRetryWhenUnauthorizedAndRefreshFailsDoesNotRetryAndTriggersLogout() async {
        let authSessionService = AuthSessionServiceStub(
            refreshResult: .failure(StubError.any)
        )
        let sut = RetryInterceptor(authSessionService: authSessionService)
        let (session, request) = await makeCompletedRequest(
            statusCode: 401,
            path: "/expenses"
        )

        let retryResult = await resolveRetryResult(
            sut: sut,
            request: request,
            session: session
        )

        switch retryResult {
        case .doNotRetryWithError:
            let refreshCallCount = await authSessionService.currentRefreshCallCount()
            let logoutCallCount = await authSessionService.currentLogoutCallCount()
            XCTAssertEqual(refreshCallCount, 1)
            XCTAssertEqual(logoutCallCount, 1)
        default:
            XCTFail("Expected doNotRetryWithError")
        }
    }
}

extension RetryInterceptorTests {
    func testRetryWhenUnauthorizedForLogoutPathDoesNotRetry() async {
        let authSessionService = AuthSessionServiceStub(
            refreshResult: .success(
                AuthTokenDTO(
                    accessToken: "new-access",
                    refreshToken: "new-refresh",
                    tokenType: "bearer",
                    expiresIn: 900
                )
            )
        )
        let sut = RetryInterceptor(authSessionService: authSessionService)
        let (session, request) = await makeCompletedRequest(
            statusCode: 401,
            path: "/auth/logout"
        )

        let retryResult = await resolveRetryResult(
            sut: sut,
            request: request,
            session: session
        )

        switch retryResult {
        case .doNotRetry:
            let refreshCallCount = await authSessionService.currentRefreshCallCount()
            XCTAssertEqual(refreshCallCount, 0)
        default:
            XCTFail("Expected doNotRetry")
        }
    }
}

extension RetryInterceptorTests {
    func testRetryWhenStatusCodeIsNotUnauthorizedDoesNotRetry() async {
        let authSessionService = AuthSessionServiceStub(
            refreshResult: .success(
                AuthTokenDTO(
                    accessToken: "new-access",
                    refreshToken: "new-refresh",
                    tokenType: "bearer",
                    expiresIn: 900
                )
            )
        )
        let sut = RetryInterceptor(authSessionService: authSessionService)
        let (session, request) = await makeCompletedRequest(
            statusCode: 403,
            path: "/expenses"
        )

        let retryResult = await resolveRetryResult(
            sut: sut,
            request: request,
            session: session
        )

        switch retryResult {
        case .doNotRetry:
            let refreshCallCount = await authSessionService.currentRefreshCallCount()
            XCTAssertEqual(refreshCallCount, 0)
        default:
            XCTFail("Expected doNotRetry")
        }
    }
}

private extension RetryInterceptorTests {
    func resolveRetryResult(
        sut: RetryInterceptor,
        request: Request,
        session: Session
    ) async -> RetryResult {
        await withCheckedContinuation { continuation in
            sut.retry(request, for: session, dueTo: StubError.any) { retryResult in
                continuation.resume(returning: retryResult)
            }
        }
    }

    func makeCompletedRequest(
        statusCode: Int,
        path: String
    ) async -> (Session, DataRequest) {
        URLProtocolStub.responseStatusCode = statusCode

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = Session(configuration: configuration)
        let request = session.request("https://example.com\(path)")
        let responseExpectation = expectation(description: "response")

        request.response { _ in
            responseExpectation.fulfill()
        }

        await fulfillment(of: [responseExpectation], timeout: 1.0)
        return (session, request)
    }

    enum StubError: Error {
        case any
    }
}

private actor AuthSessionServiceStub: AuthSessionServiceProtocol {
    private let refreshResult: Result<AuthTokenDTO, Error>

    private(set) var refreshCallCount: Int = .zero
    private(set) var logoutCallCount: Int = .zero

    init(refreshResult: Result<AuthTokenDTO, Error>) {
        self.refreshResult = refreshResult
    }

    func hasValidSession() async -> Bool {
        false
    }

    func refreshAccessToken() async throws -> AuthTokenDTO {
        refreshCallCount += 1

        switch refreshResult {
        case let .success(token):
            return token
        case let .failure(error):
            logoutCallCount += 1
            throw error
        }
    }

    func accessToken() async -> String? {
        nil
    }

    func logoutFromBackend() async throws {}

    func logout() async {
        logoutCallCount += 1
    }

    func currentRefreshCallCount() -> Int {
        refreshCallCount
    }

    func currentLogoutCallCount() -> Int {
        logoutCallCount
    }
}

private final class URLProtocolStub: URLProtocol {
    static var responseStatusCode: Int = 200

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else {
            return
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: Self.responseStatusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(
            self,
            didReceive: response,
            cacheStoragePolicy: .notAllowed
        )
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
