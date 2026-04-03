// Created by Egor Shkarin on 28.03.2026

import UIKit
import Nivelir
import Foundation

final class CategoryFactory: Screen {
    private let categoryID: String
    private let categoryName: String?
    private let context: MainFlowContext

    init(
        categoryID: String,
        categoryName: String?,
        context: MainFlowContext
    ) {
        self.categoryID = categoryID
        self.categoryName = categoryName
        self.context = context
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var toastPresenter: ToastPresenting

        let viewModel = CategoryViewModel()
        let presenter = CategoryPresenter(
            viewModel: viewModel,
            formatter: MainValueFormatter(),
            colorProvider: CategoryColorProvider()
        )
        let router = CategoryRouter(
            screenRouter: navigator,
            toastPresenter: toastPresenter
        )
        let interactor = CategoryInteractor(
            categoryID: categoryID,
            categoryName: categoryName,
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

        let collectionAdapter = CategoryExpensesCollectionViewAdapter()
        let controller = CategoryViewController(
            interactor: interactor,
            viewModelStore: viewModelStore,
            collectionAdapter: collectionAdapter
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
