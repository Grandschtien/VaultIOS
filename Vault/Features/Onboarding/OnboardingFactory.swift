// Created by Egor Shkarin 11.03.2026

import UIKit
import Nivelir
import Foundation

final class OnboardingFactory: Screen {
    func build(navigator: ScreenNavigator) -> UIViewController {
        let viewModel = OnboardingViewModel()
        let presenter = OnboardingPresenter(viewModel: viewModel)
        let router = OnboardingRouter(screenRouter: navigator)
        let interactor = OnboardingInteractor(presenter: presenter, router: router)

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let controller = OnboardingViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )
        
        presenter.handler = interactor

        return controller
    }
}
