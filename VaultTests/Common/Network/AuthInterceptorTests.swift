import XCTest
import Foundation
import Alamofire
@testable import Vault

final class AuthInterceptorTests: XCTestCase {
    func testAdaptDoesNotAppendAuthorizationHeaderForLoginPath() async {
        let authSessionService = AuthSessionServiceStub(accessToken: "access-token")
        let sut = AuthInterceptor(authSessionService: authSessionService)
        var request = URLRequest(url: URL(string: "https://example.com/auth/login")!)
        request.httpMethod = "POST"

        let adaptedRequest = await adaptRequest(sut: sut, request: request)

        XCTAssertNil(adaptedRequest.value(forHTTPHeaderField: "Authorization"))
    }
}

extension AuthInterceptorTests {
    func testAdaptAppendsAuthorizationHeaderForProtectedPath() async {
        let authSessionService = AuthSessionServiceStub(accessToken: "access-token")
        let sut = AuthInterceptor(authSessionService: authSessionService)
        var request = URLRequest(url: URL(string: "https://example.com/expenses")!)
        request.httpMethod = "GET"

        let adaptedRequest = await adaptRequest(sut: sut, request: request)

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

private actor AuthSessionServiceStub: AuthSessionServiceProtocol {
    private let token: String?

    init(accessToken: String?) {
        self.token = accessToken
    }

    func hasValidSession() async -> Bool {
        false
    }

    func refreshAccessToken() async throws -> AuthTokenDTO {
        throw StubError.notImplemented
    }

    func accessToken() async -> String? {
        token
    }

    func logout() async {}

    enum StubError: Error {
        case notImplemented
    }
}
