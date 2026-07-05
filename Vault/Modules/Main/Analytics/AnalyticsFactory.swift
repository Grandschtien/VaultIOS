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
        var subscriptionAccessService: SubscriptionAccessServicing
        @SafeInject
        var analyticsCoreManager: AnalyticsCoreManaging
        @SafeInject
        var analyticsFailurePayloadResolver: AnalyticsFailurePayloadResolving

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
            repository: context.repository,
            analyticsIntervalRepository: context.analyticsIntervalRepository,
            dataProvider: AnalyticsDataProvider(
                categoriesService: categoriesService
            ),
            observer: context.observer,
            periodResolver: AnalyticsPeriodResolver(),
            subscriptionAccessService: subscriptionAccessService,
            analytics: AnalyticsModuleAnalyticsTracker(
                analyticsCoreManager: analyticsCoreManager,
                failurePayloadResolver: analyticsFailurePayloadResolver
            )
        )
        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )
        let controller = AnalyticsViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
