import UIKit
import Nivelir
import Foundation

final class MainFlowRootFactory: Screen {
    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var categoriesService: MainCategoriesContractServicing
        @SafeInject
        var expensesService: MainExpensesContractServicing
        @SafeInject
        var summaryService: MainSummaryContractServicing
        @SafeInject
        var currencyConversionService: UserCurrencyConverting
        @SafeInject
        var pendingRouteStore: PendingVylokRouteStoring
        @SafeInject
        var subscriptionInitializer: SubscriptionInitializerLogic
        @SafeInject
        var widgetSnapshotSyncService: VylokWidgetSnapshotSyncing
        @SafeInject
        var widgetEntryDestinationResolver: VylokWidgetEntryDestinationResolving
        @SafeInject
        var subscriptionAccessService: SubscriptionAccessServicing

        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(
            expenseGrouping: MainExpenseDateGrouping()
        )
        let summaryPeriodProvider = MainSummaryPeriodProvider()
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            summaryService: summaryService,
            summaryPeriodProvider: summaryPeriodProvider,
            currencyConversionService: currencyConversionService,
            store: store,
            observer: observer,
            widgetSnapshotSyncService: widgetSnapshotSyncService
        )
        let context = MainFlowContext(
            store: store,
            observer: observer,
            repository: repository,
            summaryPeriodProvider: summaryPeriodProvider
        )

        let widgetSubscriptionOutput = VylokWidgetSubscriptionOutputAdapter(
            widgetSnapshotSyncService: widgetSnapshotSyncService
        )
        let router = MainFlowRootRouter(screenNavigator: navigator)
        let interactor = MainFlowRootInteractor(
            context: context,
            pendingRouteStore: pendingRouteStore,
            subscriptionInitializer: subscriptionInitializer,
            widgetEntryDestinationResolver: widgetEntryDestinationResolver,
            subscriptionAccessService: subscriptionAccessService,
            widgetSubscriptionOutput: widgetSubscriptionOutput,
            router: router
        )
        let controller = MainFlowRootViewController(
            screenNavigator: navigator,
            context: context,
            interactor: interactor
        )

        router.viewController = controller

        return controller
    }
}
