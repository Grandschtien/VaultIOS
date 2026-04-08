import XCTest
import UIKit
import Nivelir
@testable import Vault

@MainActor
final class MainFlowRootViewControllerTests: XCTestCase {
    func testHomeTabUsesMainScreenAndStatsTabUsesAnalyticsScreenWithoutProfileButton() {
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 375, height: 812))
        let navigator = ScreenNavigator(window: window)
        let context = MainFlowContext(
            store: MainFlowDomainStore(),
            observer: MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping()),
            repository: MainFlowRootRepositoryStub(),
            summaryPeriodProvider: MainSummaryPeriodProviderStub()
        )
        let sut = MainFlowRootViewController(
            screenNavigator: navigator,
            context: context
        )

        _ = sut.view

        guard let tabs = sut.viewControllers else {
            return XCTFail("Expected tabs")
        }

        XCTAssertEqual(tabs.count, 2)
        XCTAssertEqual(sut.selectedIndex, 0)

        guard let homeNavigation = tabs[0] as? UINavigationController,
              let statsNavigation = tabs[1] as? UINavigationController else {
            return XCTFail("Expected navigation controllers")
        }

        XCTAssertTrue(homeNavigation.viewControllers.first is MainViewController)
        XCTAssertTrue(statsNavigation.viewControllers.first is AnalyticsViewController)
        XCTAssertNil(statsNavigation.viewControllers.first?.navigationItem.rightBarButtonItem)
        XCTAssertNotNil(homeNavigation.viewControllers.first?.navigationItem.rightBarButtonItem)
    }

    func testCenterActionPresentsAddExpenseChooserWithoutChangingSelectedTab() async {
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 375, height: 812))
        let navigator = ScreenNavigator(window: window)
        let context = MainFlowContext(
            store: MainFlowDomainStore(),
            observer: MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping()),
            repository: MainFlowRootRepositoryStub(),
            summaryPeriodProvider: MainSummaryPeriodProviderStub()
        )
        let sut = MainFlowRootViewController(
            screenNavigator: navigator,
            context: context
        )

        window.rootViewController = sut
        window.makeKeyAndVisible()
        _ = sut.view

        guard let centerActionButton = findCenterActionButton(in: sut.view) else {
            return XCTFail("Expected center action button")
        }

        centerActionButton.sendActions(for: .touchUpInside)
        await Task.yield()
        await Task.yield()

        XCTAssertEqual(sut.selectedIndex, 0)

        guard let presentedViewController = sut.presentedViewController as? ExpenseEntryChooserViewController else {
            return XCTFail("Expected expense entry chooser")
        }

        XCTAssertGreaterThan(presentedViewController.preferredContentSize.height, 0)
    }

    func testCurrencyChangeNotificationTriggersRepositoryUpdate() async {
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 375, height: 812))
        let navigator = ScreenNavigator(window: window)
        let repository = MainFlowRootRepositoryStub()
        let context = MainFlowContext(
            store: MainFlowDomainStore(),
            observer: MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping()),
            repository: repository,
            summaryPeriodProvider: MainSummaryPeriodProviderStub()
        )
        let sut = MainFlowRootViewController(
            screenNavigator: navigator,
            context: context
        )

        let payload = ProfileCurrencyDidChangePayload(
            previousCurrencyCode: "USD",
            previousRateToUsd: 1,
            updatedCurrencyCode: "EUR",
            updatedRateToUsd: 0.92
        )
        let expectation = expectation(description: "Currency event forwarded to repository")
        repository.onHandleCurrencyDidChange = { receivedPayload in
            XCTAssertEqual(receivedPayload, payload)
            expectation.fulfill()
        }

        _ = sut.view
        NotificationCenter.default.post(
            name: .profileCurrencyDidChange,
            object: payload
        )

        await fulfillment(of: [expectation], timeout: 1.0)
    }
}

private func findCenterActionButton(in rootView: UIView) -> UIButton? {
    let tabBarView = allSubviews(in: rootView).first { $0 is MainTabBarView }
    return tabBarView?.subviews.compactMap { $0 as? UIButton }.first
}

private func allSubviews(in view: UIView) -> [UIView] {
    view.subviews + view.subviews.flatMap(allSubviews)
}

private final class MainFlowRootRepositoryStub: MainFlowDomainRepositoryProtocol, @unchecked Sendable {
    var onHandleCurrencyDidChange: ((ProfileCurrencyDidChangePayload) -> Void)?

    func refreshMainFlow() async throws {}
    func refreshCategories() async throws {}
    func refreshRecentExpenses() async throws {}
    func refreshCategoryFirstPage(id: String, fromDate: Date?, toDate: Date?) async throws {}
    func refreshExpensesFirstPage() async throws {}
    func handleCurrencyDidChange(_ payload: ProfileCurrencyDidChangePayload) async {
        onHandleCurrencyDidChange?(payload)
    }
    func loadNextCategoryPage(id: String) async throws {}
    func loadNextExpensesPage() async throws {}
    func addExpense(_ request: ExpensesCreateRequestDTO) async throws {}
    func deleteExpense(id: String) async throws {}
    func addCategory(_ request: CategoryCreateRequestDTO) async throws {}
    func deleteCategory(id: String) async throws {}
    func clearSession() async {}
}

private final class MainSummaryPeriodProviderStub: MainSummaryPeriodServicing, @unchecked Sendable {
    func currentMonthPeriod() -> MainSummaryPeriod {
        .init(
            from: Date(timeIntervalSince1970: 1),
            to: Date(timeIntervalSince1970: 2)
        )
    }

    func updatePeriod(from: Date, to: Date) {}
}
