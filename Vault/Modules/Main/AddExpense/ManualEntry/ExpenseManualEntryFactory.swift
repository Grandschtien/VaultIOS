import UIKit
import Nivelir

struct ExpenseManualEntryFactory: Screen {
    private let context: MainFlowContext

    init(context: MainFlowContext) {
        self.context = context
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
            observer: context.observer,
            userProfileStorageService: userProfileStorageService,
            requestBuilder: ExpenseManualEntryRequestBuilder()
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
