import XCTest
@testable import Vault

final class VaultRouteParserTests: XCTestCase {
    private var sut: VaultRouteParser!

    override func setUp() {
        super.setUp()
        sut = VaultRouteParser()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension VaultRouteParserTests {
    func testParseHomeRoute() {
        XCTAssertEqual(sut.parse(url: VaultRoute.home.url), .home)
    }

    func testParseAIEntryRoute() {
        XCTAssertEqual(sut.parse(url: VaultRoute.aiEntry.url), .aiEntry)
    }

    func testParseUnknownRouteReturnsNil() {
        XCTAssertNil(sut.parse(url: URL(string: "vault://profile")!))
        XCTAssertNil(sut.parse(url: URL(string: "https://vault.com/home")!))
    }
}
