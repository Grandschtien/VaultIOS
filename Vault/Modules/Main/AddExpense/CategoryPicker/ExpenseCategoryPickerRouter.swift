import UIKit
import Nivelir

@MainActor
protocol ExpenseCategoryPickerRoutingLogic: Sendable {
    func close()
    func openCategoryCreate()
}

final class ExpenseCategoryPickerRouter: ExpenseCategoryPickerRoutingLogic {
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

    func close() {
        let container = viewController?.navigationController ?? viewController

        screenRouter.navigate(from: container) { route in
            route.dimiss()
        }
    }

    func openCategoryCreate() {
        guard let viewController else {
            return
        }

        screenRouter.navigate(from: viewController) { route in
            route
                .present(
                    CategoryEditorFactory(
                        mode: .create,
                        context: context
                    )
                )
        }
    }
}
