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
        var pendingRouteStore: PendingVaultRouteStoring
        @SafeInject
        var widgetSnapshotSyncService: VaultWidgetSnapshotSyncing
        @SafeInject
        var widgetEntryDestinationResolver: VaultWidgetEntryDestinationResolving

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

        return MainFlowRootViewController(
            screenNavigator: navigator,
            context: context,
            pendingRouteStore: pendingRouteStore,
            widgetEntryDestinationResolver: widgetEntryDestinationResolver
        )
    }
}
