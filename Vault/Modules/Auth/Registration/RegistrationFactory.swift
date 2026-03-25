// Created by Egor Shkarin 16.03.2026

import UIKit
import Nivelir
import Foundation
import NetworkClient

final class RegistrationFactory: Screen {
    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var networkClient: AsyncNetworkClient
        @SafeInject
        var tokenStorageService: TokenStorageServiceProtocol
        @SafeInject
        var userProfileStorageService: UserProfileStorageServiceProtocol
        @SafeInject
        var toastPresenter: ToastPresenting

        let registrationStorage = RegistrationStorage()
        let viewModel = RegistrationViewModel()
        let presenter = RegistrationPresenter(viewModel: viewModel)
        let router = RegistrationRouter(
            screenRouter: navigator,
            toastPresenter: toastPresenter
        )
        let interactor = RegistrationInteractor(
            networkClient: networkClient,
            presenter: presenter,
            router: router,
            tokenStorageService: tokenStorageService,
            userProfileStorageService: userProfileStorageService,
            registrationStorage: registrationStorage
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
