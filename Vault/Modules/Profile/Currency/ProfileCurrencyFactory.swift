import UIKit
import Nivelir

final class ProfileCurrencyFactory: Screen {
    private let currentCurrencyCode: String
    private let output: ProfileCurrencySelectionOutput

    init(
        currentCurrencyCode: String,
        output: ProfileCurrencySelectionOutput
    ) {
        self.currentCurrencyCode = currentCurrencyCode
        self.output = output
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        let currencyProvider = RegistrationCurrencyProvider()
        let viewModel = ProfileCurrencyViewModel()
        let presenter = ProfileCurrencyPresenter(viewModel: viewModel)
        let router = ProfileCurrencyRouter(screenRouter: navigator)
        let interactor = ProfileCurrencyInteractor(
            presenter: presenter,
            router: router,
            currencyProvider: currencyProvider,
            output: output,
            currentCurrencyCode: currentCurrencyCode
        )

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let tableAdapter = ProfileCurrencyTableAdapter()
        let controller = ProfileCurrencyViewController(
            interactor: interactor,
            viewModelStore: viewModelStore,
            tableAdapter: tableAdapter
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
