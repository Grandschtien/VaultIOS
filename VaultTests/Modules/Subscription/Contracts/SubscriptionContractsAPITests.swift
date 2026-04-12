import XCTest
@testable import Vault

final class SubscriptionContractsAPITests: XCTestCase {
    func testApproveBuildsExpectedConfiguration() {
        let target = SubscriptionAPI.approve(
            .init(
                signedTransactionInfo: "signed-transaction"
            )
        )

        XCTAssertEqual(target.path, "/subscriptions/apple/approve")
        XCTAssertEqual(target.method.rawValue, "POST")
        XCTAssertEqual(target.host, "localhost")
        XCTAssertEqual(target.timeoutInterval, 30)
        XCTAssertEqual(target.url.absoluteString, "https://localhost:8080/subscriptions/apple/approve")

        guard case .custonJSON = target.requestType else {
            return XCTFail("Expected custom JSON request type")
        }
    }
}
