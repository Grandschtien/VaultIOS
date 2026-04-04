import XCTest
import UIKit
import Nivelir
@testable import Vault

@MainActor
final class DismissActionsTests: XCTestCase {
    func testDimissDismissesCurrentPresentedController() async throws {
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 375, height: 812))
        let rootViewController = UIViewController()
        let navigator = ScreenNavigator(window: window)

        window.rootViewController = rootViewController
        window.makeKeyAndVisible()

        navigator.navigate(from: rootViewController) { route in
            route.present(TestModalScreen(identifier: "first"), animated: false)
        }
        await settleNavigation()

        let firstPresented = try XCTUnwrap(rootViewController.presentedViewController as? TestModalViewController)

        navigator.navigate(from: firstPresented) { route in
            route.dimiss(animated: false)
        }
        await settleNavigation()

        XCTAssertNil(rootViewController.presentedViewController)
    }

    func testDimissAndPresentDismissesCurrentControllerAndPresentsNewBottomSheet() async throws {
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 375, height: 812))
        let rootViewController = UIViewController()
        let navigator = ScreenNavigator(window: window)

        window.rootViewController = rootViewController
        window.makeKeyAndVisible()

        navigator.navigate(from: rootViewController) { route in
            route.present(
                TestModalScreen(identifier: "first")
                    .withBottomSheet(.init(detents: [.content])),
                animated: false
            )
        }
        await settleNavigation()

        let firstPresented = try XCTUnwrap(rootViewController.presentedViewController as? TestModalViewController)

        navigator.navigate(from: firstPresented) { route in
            route.dimissAndPresent(
                TestModalScreen(identifier: "second")
                    .withBottomSheet(.init(detents: [.content])),
                animated: false
            )
        }
        await settleNavigation()

        let secondPresented = try XCTUnwrap(rootViewController.presentedViewController as? TestModalViewController)

        XCTAssertEqual(secondPresented.identifier, "second")
        XCTAssertTrue(rootViewController.presentedViewController === secondPresented)
        XCTAssertFalse(rootViewController.presentedViewController === firstPresented)
        XCTAssertEqual(secondPresented.modalPresentationStyle, .custom)
        XCTAssertNotNil(secondPresented.transitioningDelegate)
    }
}

@MainActor
private func settleNavigation() async {
    await Task.yield()
    await Task.yield()
    await Task.yield()
}

private struct TestModalScreen: Screen {
    let identifier: String

    func build(navigator: ScreenNavigator) -> UIViewController {
        TestModalViewController(identifier: identifier)
    }
}

private final class TestModalViewController: UIViewController {
    let identifier: String

    init(identifier: String) {
        self.identifier = identifier
        super.init(nibName: nil, bundle: nil)
        preferredContentSize = .init(width: 320, height: 240)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
