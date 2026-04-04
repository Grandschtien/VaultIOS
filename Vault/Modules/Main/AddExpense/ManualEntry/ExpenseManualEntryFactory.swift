import UIKit
import Nivelir

final class ExpenseManualEntryFactory: Screen {
    private let context: MainFlowContext

    init(context: MainFlowContext) {
        self.context = context
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var toastPresenter: ToastPresenting

        let viewModel = ExpenseManualEntryViewModel()
        let presenter = ExpenseManualEntryPresenter(
            viewModel: viewModel,
            colorProvider: CategoryColorProvider()
        )
        let router = ExpenseManualEntryRouter(
            screenRouter: navigator,
            context: context,
            toastPresenter: toastPresenter
        )
        let interactor = ExpenseManualEntryInteractor(
            presenter: presenter,
            router: router
        )

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let controller = ExpenseManualEntryViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
