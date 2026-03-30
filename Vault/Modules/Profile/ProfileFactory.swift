// Created by Egor Shkarin 29.03.2026

import UIKit
import Nivelir
import Foundation

final class ProfileFactory: Screen {
    func build(navigator: ScreenNavigator) -> UIViewController {
        let viewModel = ProfileViewModel()
        let presenter = ProfilePresenter(viewModel: viewModel)
        let router = ProfileRouter(screenRouter: navigator)
        let interactor = ProfileInteractor(presenter: presenter, router: router)

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let controller = ProfileViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
