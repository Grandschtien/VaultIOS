import XCTest
@testable import Vault

final class MainDataStoreCacheTests: XCTestCase {
    func testSaveAndReadSummaryByCategoryID() {
        let cache = MainDataStoreCache()
        let summary = SummaryResponseDTO(
            category: "cat-1",
            total: 123.45,
            currency: "USD",
            byCategory: nil
        )

        cache.save(summary: summary, for: "cat-1")

        XCTAssertEqual(cache.summary(for: "cat-1"), summary)
    }
}

extension MainDataStoreCacheTests {
    func testNewInstanceStartsEmpty() {
        let cache = MainDataStoreCache()

        XCTAssertNil(cache.summary(for: "unknown"))
    }
}

extension MainDataStoreCacheTests {
    func testClearRemovesSavedSummaries() {
        let cache = MainDataStoreCache()
        cache.save(
            summary: SummaryResponseDTO(
                category: "cat-1",
                total: 10,
                currency: "USD",
                byCategory: nil
            ),
            for: "cat-1"
        )

        cache.clear()

        XCTAssertNil(cache.summary(for: "cat-1"))
    }
}
