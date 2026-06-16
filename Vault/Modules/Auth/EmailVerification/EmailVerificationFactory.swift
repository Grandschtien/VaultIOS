import Foundation
import Nivelir
import UIKit

final class EmailVerificationFactory: Screen {
    private let context: EmailVerificationContext
    private let registrationStorage: RegistrationStorageProtocol?

    init(
        context: EmailVerificationContext,
        registrationStorage: RegistrationStorageProtocol? = nil
    ) {
        self.context = context
        self.registrationStorage = registrationStorage
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var authVerificationService: AuthVerificationContractServicing
        @SafeInject
        var tokenStorageService: TokenStorageServiceProtocol
        @SafeInject
        var userProfileStorageService: UserProfileStorageServiceProtocol
        @SafeInject
        var toastPresenter: ToastPresenting
        @SafeInject
        var subscriptionInitializer: SubscriptionInitializerLogic

        let viewModel = EmailVerificationViewModel()
        let presenter = EmailVerificationPresenter(viewModel: viewModel)
        let router = EmailVerificationRouter(
            screenRouter: navigator,
            toastPresenter: toastPresenter
        )
        let interactor = EmailVerificationInteractor(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            tokenStorageService: tokenStorageService,
            userProfileStorageService: userProfileStorageService,
            subscriptionInitializer: subscriptionInitializer,
            context: context,
            registrationStorage: registrationStorage
        )
        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )
        let controller = EmailVerificationViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor

        return controller
    }
}
