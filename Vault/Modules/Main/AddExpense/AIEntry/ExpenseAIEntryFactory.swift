import UIKit
import Nivelir

struct ExpenseAIEntryFactory: Screen {
    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var toastPresenter: ToastPresenting

        let viewModel = ExpenseAIEntryViewModel()
        let presenter = ExpenseAIEntryPresenter(viewModel: viewModel)
        let router = ExpenseAIEntryRouter(
            screenRouter: navigator,
            toastPresenter: toastPresenter
        )
        let interactor = ExpenseAIEntryInteractor(
            presenter: presenter,
            router: router
        )

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let controller = ExpenseAIEntryViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
