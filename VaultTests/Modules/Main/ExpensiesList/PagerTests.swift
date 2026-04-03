import XCTest
@testable import Vault

final class PagerTests: XCTestCase {
    func testInitialStateHasMoreWithNilCursor() async {
        let sut = Pager()

        let hasMorePages = await sut.hasMorePages()
        let isLoadingPage = await sut.isLoadingPage()

        XCTAssertTrue(hasMorePages)
        XCTAssertFalse(isLoadingPage)
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
        let isLoadingPage = await sut.isLoadingPage()
        XCTAssertTrue(isLoadingPage)
    }
}

extension PagerTests {
    func testCommitPageUpdatesCursorAndHasMore() async {
        let sut = Pager()

        _ = await sut.beginNextPageIfPossible()
        await sut.commitPage(nextCursor: "cursor-2", hasMore: true)
        let nextRequest = await sut.beginNextPageIfPossible()

        XCTAssertEqual(nextRequest?.cursor, "cursor-2")
        let hasMorePages = await sut.hasMorePages()
        let isLoadingPage = await sut.isLoadingPage()

        XCTAssertTrue(hasMorePages)
        XCTAssertTrue(isLoadingPage)
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
        let hasMorePages = await sut.hasMorePages()
        XCTAssertTrue(hasMorePages)
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
        let isLoadingPage = await sut.isLoadingPage()
        XCTAssertTrue(isLoadingPage)
    }
}
