// Created by Egor Shkarin 29.03.2026

import UIKit
import Nivelir
import Foundation

final class ProfileFactory: Screen {
    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var profileService: ProfileContractServicing
        @SafeInject
        var currencyRateService: MainCurrencyRateContractServicing
        @SafeInject
        var userProfileStorageService: UserProfileStorageServiceProtocol
        @SafeInject
        var authSessionService: AuthSessionServiceProtocol
        @SafeInject
        var toastPresenter: ToastPresenting
        @SafeInject
        var subscriptionAccessService: SubscriptionAccessServicing

        let viewModel = ProfileViewModel()
        let presenter = ProfilePresenter(viewModel: viewModel)
        let router = ProfileRouter(
            screenRouter: navigator,
            toastPresenter: toastPresenter
        )
        let interactor = ProfileInteractor(
            presenter: presenter,
            router: router,
            profileService: profileService,
            currencyRateService: currencyRateService,
            userProfileStorageService: userProfileStorageService,
            authSessionService: authSessionService,
            subscriptionAccessService: subscriptionAccessService
        )

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let controller = ProfileViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
