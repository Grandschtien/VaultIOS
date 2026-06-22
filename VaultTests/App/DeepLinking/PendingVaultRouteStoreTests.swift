import XCTest
@testable import Vault

final class PendingVaultRouteStoreTests: XCTestCase {
    private var sut: PendingVaultRouteStore!

    override func setUp() {
        super.setUp()
        sut = PendingVaultRouteStore()
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
}
