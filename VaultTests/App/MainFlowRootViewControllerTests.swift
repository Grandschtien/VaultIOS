import XCTest
import UIKit
import Nivelir
@testable import Vault

@MainActor
final class MainFlowRootViewControllerTests: XCTestCase {
    func testHomeTabUsesMainScreenAndStatsTabRemainsPlaceholder() {
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 375, height: 812))
        let navigator = ScreenNavigator(window: window)
        let sut = MainFlowRootViewController(screenNavigator: navigator)

        _ = sut.view

        guard let tabs = sut.viewControllers else {
            return XCTFail("Expected tabs")
        }

        XCTAssertEqual(tabs.count, 2)
        XCTAssertEqual(sut.selectedIndex, 0)

        guard let homeNavigation = tabs[0] as? UINavigationController,
              let statsNavigation = tabs[1] as? UINavigationController
        else {
            return XCTFail("Expected navigation controllers")
        }

        XCTAssertTrue(homeNavigation.viewControllers.first is MainViewController)
        XCTAssertEqual(statsNavigation.viewControllers.first?.title, L10n.mainTabStats)
    }
}
