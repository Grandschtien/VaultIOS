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
    private let context: MainFlowContext

    weak var viewController: UIViewController?

    init(
        screenRouter: ScreenNavigator,
        context: MainFlowContext
    ) {
        self.screenRouter = screenRouter
        self.context = context
    }

    func openAiEntry() {
        guard let viewController else {
            return
        }

        screenRouter.navigate(from: viewController) { route in
            route
                .stack(of: BottomSheetStackController.self)
                .push(ExpenseAIEntryFactory()) { route in
                    route.changeBottomSheet { bottomSheet in
                        AddExpenseBottomSheetConfiguration.applyAiEntry(to: bottomSheet)
                    }
                }
        }
    }

    func openManualEntry() {
        guard let viewController else {
            return
        }

        screenRouter.navigate(from: viewController) { route in
            route
                .stack(of: BottomSheetStackController.self)
                .push(ExpenseManualEntryFactory(context: context)) { route in
                    route.changeBottomSheet { bottomSheet in
                        AddExpenseBottomSheetConfiguration.applyManualEntry(to: bottomSheet)
                    }
                }
        }
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
