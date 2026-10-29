import XCTest
import Foundation
import Alamofire
@testable import Vylok

final class AuthInterceptorTests: XCTestCase {
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

// MARK: - adapt

extension AuthInterceptorTests {
    func testAdaptWhenPathIsLoginDoesNotAppendAuthorizationHeader() async {
        // Arrange
        let sut = AuthInterceptor(authSessionService: authSessionService)
        authSessionService.accessTokenReturnValue = "access-token"
        var request = URLRequest(url: URL(string: "https://example.com/auth/login")!)
        request.httpMethod = "POST"

        // Act
        let adaptedRequest = await adaptRequest(sut: sut, request: request)

        // Assert
        XCTAssertNil(adaptedRequest.value(forHTTPHeaderField: "Authorization"))
    }

    func testAdaptWhenPathIsLogoutDoesNotAppendAuthorizationHeader() async {
        // Arrange
        let sut = AuthInterceptor(authSessionService: authSessionService)
        authSessionService.accessTokenReturnValue = "access-token"
        var request = URLRequest(url: URL(string: "https://example.com/auth/logout")!)
        request.httpMethod = "POST"

        // Act
        let adaptedRequest = await adaptRequest(sut: sut, request: request)

        // Assert
        XCTAssertNil(adaptedRequest.value(forHTTPHeaderField: "Authorization"))
    }

    func testAdaptWhenPathIsProtectedAppendsAuthorizationHeader() async {
        // Arrange
        let sut = AuthInterceptor(authSessionService: authSessionService)
        authSessionService.accessTokenReturnValue = "access-token"
        var request = URLRequest(url: URL(string: "https://example.com/expenses")!)
        request.httpMethod = "GET"

        // Act
        let adaptedRequest = await adaptRequest(sut: sut, request: request)

        // Assert
        XCTAssertEqual(adaptedRequest.value(forHTTPHeaderField: "Authorization"), "Bearer access-token")
    }
}

private extension AuthInterceptorTests {
    func adaptRequest(sut: AuthInterceptor, request: URLRequest) async -> URLRequest {
        let session = Session(configuration: .ephemeral)

        return await withCheckedContinuation { continuation in
            sut.adapt(request, for: session) { result in
                switch result {
                case let .success(adapted):
                    continuation.resume(returning: adapted)
                case .failure:
                    continuation.resume(returning: request)
                }
            }
        }
    }
}
