// Created by Egor Shkarin 23.03.2026

import UIKit
import Nivelir
import Foundation

final class MainFactory: Screen {
    private let context: MainFlowContext

    init(context: MainFlowContext) {
        self.context = context
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var summaryService: MainSummaryContractServicing
        @SafeInject
        var currencyRateService: MainCurrencyRateContractServicing
        @SafeInject
        var userProfileStorageService: UserProfileStorageServiceProtocol

        let currencyRateProvider = MainCurrencyRateProvider(
            currencyRateService: currencyRateService,
            userProfileStorageService: userProfileStorageService
        )
        let summaryPeriodProvider = MainSummaryPeriodProvider()
        let summaryProvider = MainSummaryProvider(
            summaryService: summaryService,
            summaryPeriodProvider: summaryPeriodProvider
        )
        let formatter = MainValueFormatter()
        let colorProvider = CategoryColorProvider()
        let categoriesCollectionAdapter = CategoryCollectionViewAdapter()

        let viewModel = MainViewModel()
        let presenter = MainPresenter(
            viewModel: viewModel,
            formatter: formatter,
            colorProvider: colorProvider,
            summaryPeriodProvider: summaryPeriodProvider
        )
        let router = MainRouter(
            screenRouter: navigator,
            context: context
        )
        let interactor = MainInteractor(
            presenter: presenter,
            router: router,
            currencyRateProvider: currencyRateProvider,
            summaryProvider: summaryProvider,
            repository: context.repository,
            observer: context.observer
        )

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let controller = MainViewController(
            interactor: interactor,
            viewModelStore: viewModelStore,
            categoriesCollectionAdapter: categoriesCollectionAdapter
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
