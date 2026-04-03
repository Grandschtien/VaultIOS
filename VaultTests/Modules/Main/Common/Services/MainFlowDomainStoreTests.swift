import XCTest
@testable import Vault

final class MainFlowDomainStoreTests: XCTestCase {
    func testUpdateAndSnapshotPersistDomainState() {
        let store = MainFlowDomainStore()

        store.update { state in
            let category = MainCategoryCardModel(
                id: "cat-1",
                name: "Food",
                icon: "🍴",
                color: "light_orange",
                amount: 12,
                currency: "USD"
            )
            let expense = MainExpenseModel(
                id: "exp-1",
                title: "Coffee",
                description: "Morning",
                amount: 4,
                currency: "USD",
                category: "cat-1",
                timeOfAdd: Date(timeIntervalSince1970: 100)
            )

            state.categoriesByID[category.id] = category
            state.categoryOrder = [category.id]
            state.expensesByID[expense.id] = expense
            state.recentExpenseIDs = [expense.id]
        }

        let snapshot = store.snapshot()

        XCTAssertEqual(snapshot.categoryOrder, ["cat-1"])
        XCTAssertEqual(snapshot.recentExpenseIDs, ["exp-1"])
        XCTAssertEqual(snapshot.categoriesByID["cat-1"]?.amount, 12)
        XCTAssertEqual(snapshot.expensesByID["exp-1"]?.title, "Coffee")
    }
}

extension MainFlowDomainStoreTests {
    func testClearRemovesStoredState() {
        let store = MainFlowDomainStore()

        store.update { state in
            state.categoryOrder = ["cat-1"]
            state.recentExpenseIDs = ["exp-1"]
        }

        store.clear()
        let snapshot = store.snapshot()

        XCTAssertTrue(snapshot.categoryOrder.isEmpty)
        XCTAssertTrue(snapshot.recentExpenseIDs.isEmpty)
        XCTAssertTrue(snapshot.categoriesByID.isEmpty)
        XCTAssertTrue(snapshot.expensesByID.isEmpty)
    }
}
