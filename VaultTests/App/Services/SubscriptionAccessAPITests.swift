import XCTest
@testable import Vault

final class SubscriptionAccessAPITests: XCTestCase {
    func testGetBuildsExpectedConfiguration() {
        let target = SubscriptionAccessAPI.get

        XCTAssertEqual(target.path, "/user/subscription")
        XCTAssertEqual(target.method.rawValue, "GET")
        XCTAssertEqual(target.host, "localhost")
        XCTAssertEqual(target.timeoutInterval, 30)
        XCTAssertEqual(target.url.absoluteString, "https://localhost:8080/user/subscription")

        guard case .plain = target.requestType else {
            return XCTFail("Expected plain request type")
        }
    }
}
