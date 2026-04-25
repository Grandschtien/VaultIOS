import UIKit
import Nivelir

struct ExpenseAIEntryFactory: Screen {
    private let context: MainFlowContext

    init(context: MainFlowContext) {
        self.context = context
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var toastPresenter: ToastPresenting
        @SafeInject
        var aiParseService: MainAIParseContractServicing
        @SafeInject
        var subscriptionAccessService: SubscriptionAccessServicing
        @SafeInject
        var voiceRecordingService: ExpenseAIEntryVoiceRecordingServicing
        @SafeInject
        var userProfileStorageService: UserProfileStorageServiceProtocol

        let viewModel = ExpenseAIEntryViewModel()
        let presenter = ExpenseAIEntryPresenter(viewModel: viewModel)
        let router = ExpenseAIEntryRouter(
            screenRouter: navigator,
            screens: AddExpenseScreens(context: context),
            toastPresenter: toastPresenter,
            noExpenseAlertPresenter: ExpenseAIEntryNoExpenseAlertPresenter()
        )
        let interactor = ExpenseAIEntryInteractor(
            presenter: presenter,
            router: router,
            aiParseService: aiParseService,
            subscriptionAccessService: subscriptionAccessService,
            subscriptionLimitErrorResolver: ExpenseAIEntrySubscriptionLimitErrorResolver(),
            voiceRecordingService: voiceRecordingService,
            observer: context.observer,
            currencyCodeResolver: AddExpenseCurrencyCodeResolver(
                observer: context.observer,
                userProfileStorageService: userProfileStorageService
            ),
            draftMapper: ExpenseAIParsedDraftMapper()
        )

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let controller = ExpenseAIEntryViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
