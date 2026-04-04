import UIKit
import Nivelir

final class ExpenseEntryChooserFactory: Screen {
    private let context: MainFlowContext

    init(context: MainFlowContext) {
        self.context = context
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        let viewModel = ExpenseEntryChooserViewModel()
        let presenter = ExpenseEntryChooserPresenter(viewModel: viewModel)
        let router = ExpenseEntryChooserRouter(
            screenRouter: navigator,
            context: context
        )
        let interactor = ExpenseEntryChooserInteractor(
            presenter: presenter,
            router: router
        )

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let controller = ExpenseEntryChooserViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
