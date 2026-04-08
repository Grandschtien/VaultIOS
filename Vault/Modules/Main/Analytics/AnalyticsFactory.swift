import UIKit
import Nivelir
import Foundation

final class AnalyticsFactory: Screen {
    private let context: MainFlowContext

    init(context: MainFlowContext) {
        self.context = context
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var categoriesService: MainCategoriesContractServicing
        @SafeInject
        var currencyConversionService: UserCurrencyConverting

        let viewModel = AnalyticsViewModel()
        let presenter = AnalyticsPresenter(
            viewModel: viewModel,
            formatter: AnalyticsValueFormatter(),
            colorProvider: CategoryColorProvider()
        )
        let router = AnalyticsRouter(
            screenRouter: navigator,
            context: context
        )
        let interactor = AnalyticsInteractor(
            presenter: presenter,
            router: router,
            dataProvider: AnalyticsDataProvider(
                categoriesService: categoriesService,
                currencyConversionService: currencyConversionService
            ),
            observer: context.observer,
            summaryPeriodProvider: context.summaryPeriodProvider
        )
        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )
        let tableAdapter = AnalyticsCategorySummaryTableAdapter()
        let controller = AnalyticsViewController(
            interactor: interactor,
            viewModelStore: viewModelStore,
            tableAdapter: tableAdapter
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
