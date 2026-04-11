// Created by Egor Shkarin 08.04.2026

import UIKit
import Nivelir
import Foundation

final class SubscriptionFactory: Screen {
    private let currentTier: String
    private let output: SubscriptionOutput

    init(
        currentTier: String,
        output: SubscriptionOutput
    ) {
        self.currentTier = currentTier
        self.output = output
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var storeKitService: SubscriptionStoreKitServicing
        @SafeInject
        var contractService: SubscriptionContractServicing
        @SafeInject
        var toastPresenter: ToastPresenting

        let viewModel = SubscriptionViewModel()
        let presenter = SubscriptionPresenter(viewModel: viewModel)
        let router = SubscriptionRouter(
            screenRouter: navigator,
            toastPresenter: toastPresenter
        )
        let interactor = SubscriptionInteractor(
            presenter: presenter,
            router: router,
            currentTier: currentTier,
            output: output,
            storeKitService: storeKitService,
            contractService: contractService
        )

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let controller = SubscriptionViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
