import UIKit
import Nivelir

@MainActor
protocol ProfileCurrencyRoutingLogic: Sendable {
    func close()
}

final class ProfileCurrencyRouter: ProfileCurrencyRoutingLogic {
    private let screenRouter: ScreenNavigator

    weak var viewController: UIViewController?

    init(screenRouter: ScreenNavigator) {
        self.screenRouter = screenRouter
    }

    func close() {
        let container = viewController?.navigationController ?? viewController

        screenRouter.navigate(from: container) { route in
            route.dimiss()
        }
    }
}
