import UIKit
import Nivelir

@MainActor
protocol ExpenseCategoryPickerRoutingLogic: Sendable {
    func close()
}

final class ExpenseCategoryPickerRouter: ExpenseCategoryPickerRoutingLogic {
    private let screenRouter: ScreenNavigator

    weak var viewController: UIViewController?

    init(screenRouter: ScreenNavigator) {
        self.screenRouter = screenRouter
    }

    func close() {
        let container = viewController?.navigationController ?? viewController

        screenRouter.navigate(from: container) { route in
            route.presenting { presentingRoute in
                presentingRoute.dismiss()
            }
        }
    }
}
