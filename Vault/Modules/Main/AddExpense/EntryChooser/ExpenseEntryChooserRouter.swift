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
        screenRouter.navigate(to: { route in
            route
                .top(.container)
                .dismiss()
                .present(
                    screens.aiEntryScreen()
                        .withBottomSheet(.init(detents: [.content]))
                )
        })
    }
    
    func openManualEntry() {
        screenRouter.navigate(to: { route in
            route
                .top(.container)
                .dismiss()
                .present(
                    screens.manualEntryScreen()
                        .withBottomSheet(.init(detents: [.content]))
                )
        })
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
