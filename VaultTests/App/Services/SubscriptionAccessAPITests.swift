import XCTest
@testable import Vylok

final class SubscriptionAccessAPITests: XCTestCase {
    func testGetBuildsExpectedConfiguration() {
        let target = SubscriptionAccessAPI.get

        XCTAssertEqual(target.path, "/user/subscription")
        XCTAssertEqual(target.method.rawValue, "GET")
        XCTAssertEqual(target.host, MainAPIConfiguration.host)
        XCTAssertEqual(target.timeoutInterval, 30)
        XCTAssertEqual(target.url, MainAPIConfiguration.url(path: "/user/subscription"))

        guard case .plain = target.requestType else {
            return XCTFail("Expected plain request type")
        }
    }
}
