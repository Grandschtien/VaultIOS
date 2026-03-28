import XCTest
@testable import Vault

final class MainDataStoreCacheTests: XCTestCase {
    func testSaveAndReadCategories() {
        let cache = MainDataStoreCache()
        let categories = [
            MainCategoryCardModel(
                id: "cat-1",
                name: "Food",
                icon: "🍴",
                color: "light_orange",
                amount: 50,
                currency: "USD"
            )
        ]

        cache.save(categories: categories)

        XCTAssertEqual(cache.categories(), categories)
    }
}

extension MainDataStoreCacheTests {
    func testNewInstanceStartsEmpty() {
        let cache = MainDataStoreCache()

        XCTAssertNil(cache.categories())
    }
}

extension MainDataStoreCacheTests {
    func testClearRemovesSavedCategories() {
        let cache = MainDataStoreCache()
        cache.save(
            categories: [
                MainCategoryCardModel(
                    id: "cat-1",
                    name: "Food",
                    icon: "🍴",
                    color: "light_orange",
                    amount: 10,
                    currency: "USD"
                )
            ]
        )

        cache.clear()

        XCTAssertNil(cache.categories())
    }
}
