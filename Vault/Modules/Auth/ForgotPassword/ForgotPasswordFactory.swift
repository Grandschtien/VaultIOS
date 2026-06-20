import UIKit
import Nivelir
import Foundation

final class ForgotPasswordFactory: Screen {
    private let context: ForgotPasswordContext

    init(context: ForgotPasswordContext = .init()) {
        self.context = context
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var toastPresenter: ToastPresenting
        @SafeInject
        var passwordRestorationService: PasswordRestorationContractServicing
        @SafeInject
        var analyticsCoreManager: AnalyticsCoreManaging
        @SafeInject
        var analyticsFailurePayloadResolver: AnalyticsFailurePayloadResolving

        let viewModel = ForgotPasswordViewModel()
        let presenter = ForgotPasswordPresenter(viewModel: viewModel)
        let analytics = ForgotPasswordAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: analyticsFailurePayloadResolver
        )
        let router = ForgotPasswordRouter(
            screenRouter: navigator,
            toastPresenter: toastPresenter
        )
        let interactor = ForgotPasswordInteractor(
            passwordRestorationService: passwordRestorationService,
            presenter: presenter,
            router: router,
            context: context,
            analytics: analytics
        )
        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )
        let controller = ForgotPasswordViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
