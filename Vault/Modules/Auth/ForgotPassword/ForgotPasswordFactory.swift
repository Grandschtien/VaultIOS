import UIKit
import Nivelir
import Foundation

final class ForgotPasswordFactory: Screen {
    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var toastPresenter: ToastPresenting
        @SafeInject
        var passwordRestorationService: PasswordRestorationContractServicing

        let viewModel = ForgotPasswordViewModel()
        let presenter = ForgotPasswordPresenter(viewModel: viewModel)
        let router = ForgotPasswordRouter(
            screenRouter: navigator,
            toastPresenter: toastPresenter
        )
        let interactor = ForgotPasswordInteractor(
            passwordRestorationService: passwordRestorationService,
            presenter: presenter,
            router: router
        )
        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )
        let controller = ForgotPasswordViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
