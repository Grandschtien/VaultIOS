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
            observer: observer
        )
        let context = MainFlowContext(
            store: store,
            observer: observer,
            repository: repository
        )

        return MainFlowRootViewController(
            screenNavigator: navigator,
            context: context
        )
    }
}
