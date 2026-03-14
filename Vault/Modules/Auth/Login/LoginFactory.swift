// Created by Egor Shkarin 14.03.2026

import UIKit
import Nivelir
import Foundation

final class LoginFactory: Screen {
    func build(navigator: ScreenNavigator) -> UIViewController {
        let viewModel = LoginViewModel()
        let presenter = LoginPresenter(viewModel: viewModel)
        let router = LoginRouter(screenRouter: navigator)
        let interactor = LoginInteractor(presenter: presenter, router: router)

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let controller = LoginViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
