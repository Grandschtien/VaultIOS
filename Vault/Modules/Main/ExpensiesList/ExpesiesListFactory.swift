// Created by Egor Shkarin 25.03.2026

import UIKit
import Nivelir
import Foundation

final class ExpesiesListFactory: Screen {
    private let context: MainFlowContext

    init(context: MainFlowContext) {
        self.context = context
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var toastPresenter: ToastPresenting

        let viewModel = ExpesiesListViewModel()
        let presenter = ExpesiesListPresenter(
            viewModel: viewModel,
            formatter: MainValueFormatter(),
            colorProvider: CategoryColorProvider()
        )
        let router = ExpesiesListRouter(
            screenRouter: navigator,
            toastPresenter: toastPresenter
        )
        let interactor = ExpesiesListInteractor(
            presenter: presenter,
            router: router,
            repository: context.repository,
            observer: context.observer
        )

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let controller = ExpesiesListViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
