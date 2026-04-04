import UIKit
import Nivelir

@MainActor
protocol ExpenseEntryChooserRoutingLogic: Sendable {
    func openAiEntry()
    func openManualEntry()
    func close()
}

final class ExpenseEntryChooserRouter: ExpenseEntryChooserRoutingLogic {
    private let screenRouter: ScreenNavigator
    private let screens: AddExpenseScreens

    weak var viewController: UIViewController?

    init(
        screenRouter: ScreenNavigator,
        screens: AddExpenseScreens
    ) {
        self.screenRouter = screenRouter
        self.screens = screens
    }

    func openAiEntry() {
        let container = viewController?.navigationController ?? viewController

        screenRouter.navigate(from: container) { route in
            route.dimissAndPresent(
                screens.aiEntryScreen()
                    .withBottomSheet(.init(detents: [.content]))
            )
        }
    }

    func openManualEntry() {
        let container = viewController?.navigationController ?? viewController

        screenRouter.navigate(from: container) { route in
            route.dimissAndPresent(
                screens.manualEntryScreen()
                    .withBottomSheet(.init(detents: [.content]))
            )
        }
    }

    func close() {
        let container = viewController?.navigationController ?? viewController

        screenRouter.navigate(from: container) { route in
            route.dimiss()
        }
    }
}
