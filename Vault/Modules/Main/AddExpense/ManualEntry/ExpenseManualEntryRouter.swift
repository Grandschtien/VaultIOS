import UIKit
import Nivelir

@MainActor
protocol ExpenseManualEntryRoutingLogic: Sendable {
    func openCategoryPicker(
        selectedCategoryID: String?,
        output: ExpenseCategoryPickerOutput
    )
    func close()
    func presentError(with text: String)
}

final class ExpenseManualEntryRouter: ExpenseManualEntryRoutingLogic {
    private let screenRouter: ScreenNavigator
    private let screens: AddExpenseScreens
    private let toastPresenter: ToastPresenting

    weak var viewController: UIViewController?

    init(
        screenRouter: ScreenNavigator,
        screens: AddExpenseScreens,
        toastPresenter: ToastPresenting
    ) {
        self.screenRouter = screenRouter
        self.screens = screens
        self.toastPresenter = toastPresenter
    }

    func openCategoryPicker(
        selectedCategoryID: String?,
        output: ExpenseCategoryPickerOutput
    ) {
        guard let viewController else {
            return
        }

        screenRouter.navigate(from: viewController) { route in
            route
                .present(
                    screens.categoryPickerScreen(
                        selectedCategoryID: selectedCategoryID,
                        output: output
                    )
                )
                .addingBottomSheet(.content)
        }
    }

    func close() {
        let container = viewController?.navigationController ?? viewController

        screenRouter.navigate(from: container) { route in
            route.dimiss()
        }
    }

    func presentError(with text: String) {
        toastPresenter.present(state: .error, title: text)
    }
}
