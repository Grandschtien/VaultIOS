import UIKit
import Nivelir

struct CategoryPeriodPickerFactory: Screen {
    private let selectedFromDate: Date
    private let selectedToDate: Date
    private let output: CategoryPeriodPickerOutput

    init(
        selectedFromDate: Date,
        selectedToDate: Date,
        output: CategoryPeriodPickerOutput
    ) {
        self.selectedFromDate = selectedFromDate
        self.selectedToDate = selectedToDate
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
            fromDate: selectedFromDate,
            toDate: selectedToDate
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
