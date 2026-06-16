// Created by Egor Shkarin 16.03.2026

import UIKit
import Nivelir
import Foundation
import NetworkClient

final class RegistrationFactory: Screen {
    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var authVerificationService: AuthVerificationContractServicing
        @SafeInject
        var toastPresenter: ToastPresenting
        @SafeInject
        var analyticsCoreManager: AnalyticsCoreManaging
        @SafeInject
        var analyticsFailurePayloadResolver: AnalyticsFailurePayloadResolving

        let registrationStorage = RegistrationStorage()
        let viewModel = RegistrationViewModel()
        let presenter = RegistrationPresenter(viewModel: viewModel)
        let analytics = RegistrationAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: analyticsFailurePayloadResolver
        )
        let router = RegistrationRouter(
            screenRouter: navigator,
            toastPresenter: toastPresenter
        )
        let interactor = RegistrationInteractor(
            authVerificationService: authVerificationService,
            presenter: presenter,
            router: router,
            registrationStorage: registrationStorage,
            analytics: analytics
        )

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let controller = RegistrationViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
