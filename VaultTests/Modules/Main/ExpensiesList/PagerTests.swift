import XCTest
@testable import Vault

final class PagerTests: XCTestCase {
    func testInitialStateHasMoreWithNilCursor() async {
        let sut = Pager()

        XCTAssertTrue(await sut.hasMorePages())
        XCTAssertFalse(await sut.isLoadingPage())
        let request = await sut.beginNextPageIfPossible()
        XCTAssertNil(request?.cursor)
    }
}

extension PagerTests {
    func testBeginNextPageReturnsNilWhenRequestAlreadyInFlight() async {
        let sut = Pager()

        let firstRequest = await sut.beginNextPageIfPossible()
        let secondRequest = await sut.beginNextPageIfPossible()

        XCTAssertNotNil(firstRequest)
        XCTAssertNil(secondRequest)
        XCTAssertTrue(await sut.isLoadingPage())
    }
}

extension PagerTests {
    func testCommitPageUpdatesCursorAndHasMore() async {
        let sut = Pager()

        _ = await sut.beginNextPageIfPossible()
        await sut.commitPage(nextCursor: "cursor-2", hasMore: true)
        let nextRequest = await sut.beginNextPageIfPossible()

        XCTAssertEqual(nextRequest?.cursor, "cursor-2")
        XCTAssertTrue(await sut.hasMorePages())
        XCTAssertTrue(await sut.isLoadingPage())
    }
}

extension PagerTests {
    func testResetRestoresInitialState() async {
        let sut = Pager()

        _ = await sut.beginNextPageIfPossible()
        await sut.commitPage(nextCursor: "cursor-3", hasMore: false)
        await sut.reset()

        let requestAfterReset = await sut.beginNextPageIfPossible()

        XCTAssertNil(requestAfterReset?.cursor)
        XCTAssertTrue(await sut.hasMorePages())
    }
}

extension PagerTests {
    func testRollbackAfterErrorAllowsNextRequest() async {
        let sut = Pager()

        _ = await sut.beginNextPageIfPossible()
        await sut.rollbackAfterError()
        let requestAfterRollback = await sut.beginNextPageIfPossible()

        XCTAssertNotNil(requestAfterRollback)
        XCTAssertNil(requestAfterRollback?.cursor)
        XCTAssertTrue(await sut.isLoadingPage())
    }
}
