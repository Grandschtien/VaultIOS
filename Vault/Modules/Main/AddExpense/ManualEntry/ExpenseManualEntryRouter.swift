import UIKit
import Nivelir

@MainActor
protocol ExpenseManualEntryRoutingLogic: Sendable {
    func openCategoryPicker(
        selectedCategoryID: String?,
        output: ExpenseCategoryPickerOutput
    )
    func close()
    func presentComingSoon()
}

final class ExpenseManualEntryRouter: ExpenseManualEntryRoutingLogic {
    private let screenRouter: ScreenNavigator
    private let context: MainFlowContext
    private let toastPresenter: ToastPresenting

    weak var viewController: UIViewController?

    init(
        screenRouter: ScreenNavigator,
        context: MainFlowContext,
        toastPresenter: ToastPresenting
    ) {
        self.screenRouter = screenRouter
        self.context = context
        self.toastPresenter = toastPresenter
    }

    func openCategoryPicker(
        selectedCategoryID: String?,
        output: ExpenseCategoryPickerOutput
    ) {
        guard let container = viewController?.navigationController ?? viewController else {
            return
        }

        let pickerScreen = ExpenseCategoryPickerFactory(
            selectedCategoryID: selectedCategoryID,
            output: output,
            context: context
        )
        .withBottomSheetStack(AddExpenseBottomSheetConfiguration.categoryPicker())

        screenRouter.navigate(from: container) { route in
            route
                .present(pickerScreen)
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

    func presentComingSoon() {
        toastPresenter.present(state: .neuteral, title: L10n.mainOverviewComingSoon)
    }
}
