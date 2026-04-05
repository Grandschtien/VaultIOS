import UIKit
import Nivelir

struct ExpenseManualEntryFactory: Screen {
    private let context: MainFlowContext
    private let initialDrafts: [ExpenseEditableDraft]

    init(
        context: MainFlowContext,
        initialDrafts: [ExpenseEditableDraft] = []
    ) {
        self.context = context
        self.initialDrafts = initialDrafts
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var toastPresenter: ToastPresenting
        @SafeInject
        var userProfileStorageService: UserProfileStorageServiceProtocol

        let viewModel = ExpenseManualEntryViewModel()
        let presenter = ExpenseManualEntryPresenter(
            viewModel: viewModel,
            colorProvider: CategoryColorProvider()
        )
        let router = ExpenseManualEntryRouter(
            screenRouter: navigator,
            screens: AddExpenseScreens(context: context),
            toastPresenter: toastPresenter
        )
        let interactor = ExpenseManualEntryInteractor(
            presenter: presenter,
            router: router,
            repository: context.repository,
            currencyCodeResolver: AddExpenseCurrencyCodeResolver(
                observer: context.observer,
                userProfileStorageService: userProfileStorageService
            ),
            requestBuilder: ExpenseManualEntryRequestBuilder(),
            initialDrafts: initialDrafts
        )

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let controller = ExpenseManualEntryViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
