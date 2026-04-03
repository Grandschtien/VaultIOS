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
