// Created by Egor Shkarin on 27.03.2026

import UIKit
import Nivelir
import Foundation

final class CategoriesListFactory: Screen {
    private let dataStoreCache: MainDataStoreCache

    init(dataStoreCache: MainDataStoreCache) {
        self.dataStoreCache = dataStoreCache
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var categoriesService: MainCategoriesContractServicing
        @SafeInject
        var currencyConversionService: UserCurrencyConverting

        let categoriesProvider = CategoriesListCategoriesProvider(
            categoriesService: categoriesService,
            cache: dataStoreCache,
            currencyConversionService: currencyConversionService
        )
        let formatter = MainValueFormatter()
        let colorProvider = CategoryColorProvider()

        let viewModel = CategoriesListViewModel()
        let presenter = CategoriesListPresenter(
            viewModel: viewModel,
            formatter: formatter,
            colorProvider: colorProvider
        )
        let router = CategoriesListRouter(screenRouter: navigator)
        let interactor = CategoriesListInteractor(
            presenter: presenter,
            router: router,
            categoriesProvider: categoriesProvider
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
