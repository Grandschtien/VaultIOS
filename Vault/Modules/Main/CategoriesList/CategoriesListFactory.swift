// Created by Egor Shkarin on 27.03.2026

import UIKit
import Nivelir
import Foundation

final class CategoriesListFactory: Screen {
    private let context: MainFlowContext

    init(context: MainFlowContext) {
        self.context = context
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        let formatter = MainValueFormatter()
        let colorProvider = CategoryColorProvider()

        let viewModel = CategoriesListViewModel()
        let presenter = CategoriesListPresenter(
            viewModel: viewModel,
            formatter: formatter,
            colorProvider: colorProvider
        )
        let router = CategoriesListRouter(
            screenRouter: navigator,
            context: context
        )
        let interactor = CategoriesListInteractor(
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

        let collectionAdapter = CategoryCollectionViewAdapter()
        let controller = CategoriesListViewController(
            interactor: interactor,
            viewModelStore: viewModelStore,
            collectionAdapter: collectionAdapter
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
