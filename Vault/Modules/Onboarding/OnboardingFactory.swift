// Created by Egor Shkarin 11.03.2026

import UIKit
import Nivelir
import Foundation

final class OnboardingFactory: Screen {
    private weak var output: OnboardingFlowOutput?

    init(output: OnboardingFlowOutput?) {
        self.output = output
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        let viewModel = OnboardingViewModel()
        let presenter = OnboardingPresenter(viewModel: viewModel)
        let interactor = OnboardingInteractor(presenter: presenter)

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
        interactor.output = output

        return controller
    }
}
