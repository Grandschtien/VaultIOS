import XCTest
import Foundation
import Alamofire
@testable import NetworkClient
@testable import Vault

final class CategoryEditorSubscriptionLimitErrorResolverTests: XCTestCase {
    func testIsSubscriptionLimitErrorWhenStatusCodeIs429ReturnsTrue() {
        let sut = CategoryEditorSubscriptionLimitErrorResolver()

        let result = sut.isSubscriptionLimitError(
            NetworkClientError.statusCode(
                code: 429,
                ResponseStub(statusCode: 429),
                ErrorMetadata(request: nil)
            )
        )

        XCTAssertTrue(result)
    }

    func testIsSubscriptionLimitErrorWhenStatusCodeIsNot429ReturnsFalse() {
        let sut = CategoryEditorSubscriptionLimitErrorResolver()

        let result = sut.isSubscriptionLimitError(
            NetworkClientError.statusCode(
                code: 500,
                ResponseStub(statusCode: 500),
                ErrorMetadata(request: nil)
            )
        )

        XCTAssertFalse(result)
    }

    func testIsSubscriptionLimitErrorWhenUnderlyingAFErrorContains429ReturnsTrue() {
        let sut = CategoryEditorSubscriptionLimitErrorResolver()

        let result = sut.isSubscriptionLimitError(
            NetworkClientError.underlying(
                AFError.responseValidationFailed(
                    reason: .unacceptableStatusCode(code: 429)
                ),
                ResponseStub(statusCode: 429),
                ErrorMetadata(request: nil)
            )
        )

        XCTAssertTrue(result)
    }

    func testIsSubscriptionLimitErrorWhenUnderlyingAFErrorContainsNon429ReturnsFalse() {
        let sut = CategoryEditorSubscriptionLimitErrorResolver()

        let result = sut.isSubscriptionLimitError(
            NetworkClientError.underlying(
                AFError.responseValidationFailed(
                    reason: .unacceptableStatusCode(code: 500)
                ),
                ResponseStub(statusCode: 500),
                ErrorMetadata(request: nil)
            )
        )

        XCTAssertFalse(result)
    }

    func testIsSubscriptionLimitErrorWhenErrorIsNotStatusCodeReturnsFalse() {
        let sut = CategoryEditorSubscriptionLimitErrorResolver()

        let result = sut.isSubscriptionLimitError(StubError.any)

        XCTAssertFalse(result)
    }
}

private struct ResponseStub: Response {
    let statusCode: Int
    let data: Data? = nil
    let request: URLRequest? = nil
    let response: HTTPURLResponse? = nil
    let description: String = ""
    let debugDescription: String = ""
}

private enum StubError: Error {
    case any
}
