// Created by Egor Shkarin ___DATE___

import UIKit
import Nivelir
import Foundation

final class ___VARIABLE_moduleName___Factory: Screen {
    func build(navigator: ScreenNavigator) -> UIViewController {
        let viewModel = ___VARIABLE_moduleName___ViewModel()
        let presenter = ___VARIABLE_moduleName___Presenter(viewModel: viewModel)
        let router = ___VARIABLE_moduleName___Router(screenRouter: navigator)
        let interactor = ___VARIABLE_moduleName___Interactor(presenter: presenter, router: router)

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let controller = ___VARIABLE_moduleName___ViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
