import XCTest
@testable import Vault

final class MainFlowDomainObserverTests: XCTestCase {
    func testSubscribeOverviewReceivesCurrentSnapshotImmediately() async {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let category = MainCategoryCardModel(
            id: "cat-1",
            name: "Food",
            icon: "🍴",
            color: "light_orange",
            amount: 15,
            currency: "USD"
        )

        store.update { state in
            state.categoriesByID[category.id] = category
            state.categoryOrder = [category.id]
        }
        observer.publishAll(from: store)

        var iterator = observer.subscribeOverview().makeAsyncIterator()
        let snapshot = await iterator.next()

        XCTAssertEqual(snapshot?.categories.first?.id, "cat-1")
    }
}

extension MainFlowDomainObserverTests {
    func testPublishAllSortsCategoriesFromLargestAmountToSmallest() {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let categories = [
            MainCategoryCardModel(
                id: "cat-1",
                name: "Food",
                icon: "🍴",
                color: "light_orange",
                amount: 5,
                currency: "USD"
            ),
            MainCategoryCardModel(
                id: "cat-2",
                name: "Taxi",
                icon: "🚕",
                color: "light_blue",
                amount: 12,
                currency: "USD"
            ),
            MainCategoryCardModel(
                id: "cat-3",
                name: "Fun",
                icon: "🎬",
                color: "light_purple",
                amount: 12,
                currency: "USD"
            )
        ]

        store.update { state in
            categories.forEach { state.categoriesByID[$0.id] = $0 }
            state.categoryOrder = categories.map(\.id)
        }
        observer.publishAll(from: store)

        XCTAssertEqual(
            observer.currentOverviewSnapshot().categories.map(\.id),
            ["cat-2", "cat-3", "cat-1"]
        )
        XCTAssertEqual(
            observer.currentCategoriesSnapshot().categories.map(\.id),
            ["cat-2", "cat-3", "cat-1"]
        )
    }
}

extension MainFlowDomainObserverTests {
    func testFinishAllCompletesSubscriptions() async {
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        var iterator = observer.subscribeCategories().makeAsyncIterator()

        _ = await iterator.next()
        observer.finishAll()
        let nextValue = await iterator.next()

        XCTAssertNil(nextValue)
    }

    func testPublishAllKeepsSummaryCurrencyAndResetsTotalWhenCategoriesBecomeEmpty() {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let category = MainCategoryCardModel(
            id: "cat-1",
            name: "Food",
            icon: "🍴",
            color: "light_orange",
            amount: 15,
            currency: "USD"
        )

        store.update { state in
            state.categoriesByID[category.id] = category
            state.categoryOrder = [category.id]
        }
        observer.publishAll(from: store)

        store.update { state in
            state.categoryOrder = []
        }
        observer.publishAll(from: store)

        let summary = observer.currentOverviewSnapshot().summary
        XCTAssertEqual(summary?.totalAmount, .zero)
        XCTAssertEqual(summary?.currency, "USD")
    }
}
