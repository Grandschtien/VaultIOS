import XCTest
import UIKit
import Nivelir
@testable import Vault

@MainActor
final class MainFlowRootViewControllerTests: XCTestCase {
    func testHomeTabUsesMainScreenAndStatsTabRemainsPlaceholder() {
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 375, height: 812))
        let navigator = ScreenNavigator(window: window)
        let context = MainFlowContext(
            store: MainFlowDomainStore(),
            observer: MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping()),
            repository: MainFlowRootRepositoryStub()
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
        XCTAssertEqual(statsNavigation.viewControllers.first?.title, L10n.mainTabStats)
    }
}

private final class MainFlowRootRepositoryStub: MainFlowDomainRepositoryProtocol, @unchecked Sendable {
    func refreshMainFlow() async throws {}
    func refreshCategories() async throws {}
    func refreshRecentExpenses() async throws {}
    func refreshCategoryFirstPage(id: String) async throws {}
    func refreshExpensesFirstPage() async throws {}
    func loadNextCategoryPage(id: String) async throws {}
    func loadNextExpensesPage() async throws {}
    func addExpense(_ request: ExpensesCreateRequestDTO) async throws {}
    func deleteExpense(id: String) async throws {}
    func addCategory(_ request: CategoryCreateRequestDTO) async throws {}
    func deleteCategory(id: String) async throws {}
    func clearSession() async {}
}
