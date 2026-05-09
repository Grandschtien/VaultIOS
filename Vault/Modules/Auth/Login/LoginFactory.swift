// Created by Egor Shkarin 14.03.2026

import UIKit
import Nivelir
import Foundation
import NetworkClient

final class LoginFactory: Screen {
    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var networkClient: AsyncNetworkClient
        @SafeInject
        var tokenStorageService: TokenStorageServiceProtocol
        @SafeInject
        var userProfileStorageService: UserProfileStorageServiceProtocol
        @SafeInject
        var toastPresenter: ToastPresenting
        @SafeInject
        var subscriptionInitializer: SubscriptionInitializerLogic
        @SafeInject
        var analyticsCoreManager: AnalyticsCoreManaging
        @SafeInject
        var analyticsFailurePayloadResolver: AnalyticsFailurePayloadResolving

        let viewModel = LoginViewModel()
        let presenter = LoginPresenter(viewModel: viewModel)
        let router = LoginRouter(screenRouter: navigator, toastPresenter: toastPresenter)
        let analytics = LoginAnalyticsTracker(
            analyticsCoreManager: analyticsCoreManager,
            failurePayloadResolver: analyticsFailurePayloadResolver
        )
        let interactor = LoginInteractor(
            networkClient: networkClient,
            presenter: presenter,
            router: router,
            tokenStorageService: tokenStorageService,
            subscriptionInitializerLogic: subscriptionInitializer,
            userProfileStorageService: userProfileStorageService,
            analytics: analytics
        )

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let controller = LoginViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor

        return controller
    }
}
