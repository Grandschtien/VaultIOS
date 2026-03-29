// Created by Egor Shkarin 25.03.2026

import UIKit
import Nivelir
import Foundation

final class ExpesiesListFactory: Screen {
    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var categoriesService: MainCategoriesContractServicing
        @SafeInject
        var expensesService: MainExpensesContractServicing
        @SafeInject
        var toastPresenter: ToastPresenting
        @SafeInject
        var currencyConversionService: UserCurrencyConverting

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
        let categoriesProvider = ExpesiesListCategoriesProvider(categoriesService: categoriesService)
        let expensesProvider = ExpesiesListExpensesProvider(
            expensesService: expensesService,
            currencyConversionService: currencyConversionService
        )
        let interactor = ExpesiesListInteractor(
            presenter: presenter,
            router: router,
            expensesProvider: expensesProvider,
            categoriesProvider: categoriesProvider,
            pager: Pager(),
            expenseGrouping: MainExpenseDateGrouping()
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
