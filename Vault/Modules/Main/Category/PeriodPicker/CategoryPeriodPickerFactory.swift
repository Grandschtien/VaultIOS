import UIKit
import Nivelir

struct CategoryPeriodPickerFactory: Screen {
    private let selectedFromDate: Date
    private let output: CategoryPeriodPickerOutput

    init(
        selectedFromDate: Date,
        output: CategoryPeriodPickerOutput
    ) {
        self.selectedFromDate = selectedFromDate
        self.output = output
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        let viewModel = CategoryPeriodPickerViewModel()
        let presenter = CategoryPeriodPickerPresenter(viewModel: viewModel)
        let router = CategoryPeriodPickerRouter(screenRouter: navigator)
        let interactor = CategoryPeriodPickerInteractor(
            presenter: presenter,
            router: router,
            output: output,
            selectedDate: selectedFromDate
        )

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let controller = CategoryPeriodPickerViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
