import XCTest
@testable import Vylok

final class VaultRouteParserTests: XCTestCase {
    private var sut: VylokRouteParser!

    override func setUp() {
        super.setUp()
        sut = VylokRouteParser()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension VaultRouteParserTests {
    func testParseHomeRoute() {
        XCTAssertEqual(sut.parse(url: VylokRoute.home.url), .home)
    }

    func testParseAIEntryRoute() {
        XCTAssertEqual(sut.parse(url: VylokRoute.aiEntry.url), .aiEntry)
    }

    func testParseSubscriptionRoute() {
        XCTAssertEqual(sut.parse(url: VylokRoute.subscription.url), .subscription)
    }

    func testParseUnknownRouteReturnsNil() {
        XCTAssertNil(sut.parse(url: URL(string: "vault://profile")!))
        XCTAssertNil(sut.parse(url: URL(string: "https://vault.com/home")!))
    }
}
