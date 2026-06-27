import XCTest
@testable import Vylok

final class PendingVaultRouteStoreTests: XCTestCase {
    private var sut: PendingVylokRouteStore!

    override func setUp() {
        super.setUp()
        sut = PendingVylokRouteStore()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension PendingVaultRouteStoreTests {
    func testConsumeReturnsStoredRouteOnce() {
        sut.store(.aiEntry)

        XCTAssertEqual(sut.consume(), .aiEntry)
        XCTAssertNil(sut.consume())
    }

    func testStoreReplacesPendingRoute() {
        sut.store(.home)
        sut.store(.aiEntry)

        XCTAssertEqual(sut.consume(), .aiEntry)
    }

    func testConsumeReturnsSubscriptionRouteOnce() {
        sut.store(.subscription)

        XCTAssertEqual(sut.consume(), .subscription)
        XCTAssertNil(sut.consume())
    }
}
