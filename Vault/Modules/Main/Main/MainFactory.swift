// Created by Egor Shkarin 23.03.2026

import UIKit
import Nivelir
import Foundation

final class MainFactory: Screen {
    func build(navigator: ScreenNavigator) -> UIViewController {
        let summaryProvider = MainSummaryProviderMock()
        let categoriesProvider = MainCategoriesProviderMock()
        let expensesProvider = MainExpensesProviderMock()
        let expenseGrouping = MainExpenseDateGrouping()
        let formatter = MainValueFormatter()

        let viewModel = MainViewModel()
        let presenter = MainPresenter(viewModel: viewModel, formatter: formatter)
        let router = MainRouter(screenRouter: navigator)
        let interactor = MainInteractor(
            presenter: presenter,
            router: router,
            summaryProvider: summaryProvider,
            categoriesProvider: categoriesProvider,
            expensesProvider: expensesProvider,
            expenseGrouping: expenseGrouping
        )

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let controller = MainViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
