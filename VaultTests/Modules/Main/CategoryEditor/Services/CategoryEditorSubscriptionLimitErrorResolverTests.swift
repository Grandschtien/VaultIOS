import XCTest
import Foundation
import Alamofire
@testable import NetworkClient
@testable import Vylok

final class CategoryEditorSubscriptionLimitErrorResolverTests: XCTestCase {
    func testIsSubscriptionLimitErrorWhenStatusCodeIs429ReturnsTrue() {
        let sut = CategoryEditorSubscriptionLimitErrorResolver()

        let result = sut.isSubscriptionLimitError(
            NetworkClientError.statusCode(
                code: 429,
                NetworkClientResponseFixtures.makeResponse(statusCode: 429),
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
                NetworkClientResponseFixtures.makeResponse(statusCode: 500),
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
                NetworkClientResponseFixtures.makeResponse(statusCode: 429),
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
                NetworkClientResponseFixtures.makeResponse(statusCode: 500),
                ErrorMetadata(request: nil)
            )
        )

        XCTAssertFalse(result)
    }

    func testIsSubscriptionLimitErrorWhenErrorIsNotStatusCodeReturnsFalse() {
        let sut = CategoryEditorSubscriptionLimitErrorResolver()

        let result = sut.isSubscriptionLimitError(TestError.any)

        XCTAssertFalse(result)
    }
}
