// Created by Egor Shkarin on 28.03.2026

import UIKit
import Nivelir
import Foundation

final class CategoryFactory: Screen {
    private let categoryID: String
    private let categoryName: String?

    init(
        categoryID: String,
        categoryName: String?
    ) {
        self.categoryID = categoryID
        self.categoryName = categoryName
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var categoriesService: MainCategoriesContractServicing
        @SafeInject
        var expensesService: MainExpensesContractServicing
        @SafeInject
        var toastPresenter: ToastPresenting
        @SafeInject
        var currencyConversionService: UserCurrencyConverting

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
            summaryProvider: CategorySummaryProvider(
                categoriesService: categoriesService,
                currencyConversionService: currencyConversionService
            ),
            expensesProvider: CategoryExpensesProvider(
                expensesService: expensesService,
                currencyConversionService: currencyConversionService
            ),
            pager: Pager(),
            expenseGrouping: MainExpenseDateGrouping()
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
