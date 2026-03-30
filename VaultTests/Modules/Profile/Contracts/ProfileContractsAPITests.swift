import XCTest
@testable import Vault

final class ProfileContractsAPITests: XCTestCase {
    func testGetBuildsExpectedConfiguration() {
        let target = ProfileAPI.get

        XCTAssertEqual(target.path, "/profile")
        XCTAssertEqual(target.method.rawValue, "GET")
        XCTAssertEqual(target.host, "localhost")
        XCTAssertEqual(target.timeoutInterval, 30)
        XCTAssertEqual(target.url.absoluteString, "https://localhost:8080/profile")

        guard case .plain = target.requestType else {
            return XCTFail("Expected plain request type")
        }
    }
}

extension ProfileContractsAPITests {
    func testUpdateBuildsExpectedConfiguration() {
        let target = ProfileAPI.update(
            .init(
                name: "Jane",
                currency: "EUR",
                preferredLanguage: "en-US"
            )
        )

        XCTAssertEqual(target.path, "/profile")
        XCTAssertEqual(target.method.rawValue, "PATCH")
        XCTAssertEqual(target.host, "localhost")
        XCTAssertEqual(target.timeoutInterval, 30)
        XCTAssertEqual(target.url.absoluteString, "https://localhost:8080/profile")

        guard case .custonJSON = target.requestType else {
            return XCTFail("Expected custom JSON request type")
        }
    }
}
