import UIKit
import Nivelir

struct ExpenseCategoryPickerFactory: Screen {
    private let selectedCategoryID: String?
    private let output: ExpenseCategoryPickerOutput
    private let context: MainFlowContext

    init(
        selectedCategoryID: String?,
        output: ExpenseCategoryPickerOutput,
        context: MainFlowContext
    ) {
        self.selectedCategoryID = selectedCategoryID
        self.output = output
        self.context = context
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        let viewModel = ExpenseCategoryPickerViewModel()
        let presenter = ExpenseCategoryPickerPresenter(
            viewModel: viewModel,
            colorProvider: CategoryColorProvider()
        )
        let router = ExpenseCategoryPickerRouter(
            screenRouter: navigator,
            context: context
        )
        let interactor = ExpenseCategoryPickerInteractor(
            presenter: presenter,
            router: router,
            repository: context.repository,
            observer: context.observer,
            output: output,
            selectedCategoryID: selectedCategoryID
        )

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let tableAdapter = ExpenseCategoryPickerTableAdapter()
        let controller = ExpenseCategoryPickerViewController(
            interactor: interactor,
            viewModelStore: viewModelStore,
            tableAdapter: tableAdapter
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
