// Created by Egor Shkarin 29.03.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol ProfileRoutingLogic: Sendable {
    func openConfirmation(context: CommonConfirmationContext)
    func openCurrencySelection(
        currentCurrencyCode: String,
        output: ProfileCurrencySelectionOutput
    )
    func openSubscription(
        currentTier: String,
        output: SubscriptionOutput
    )
    func presentError(with text: String)
}

final class ProfileRouter: ProfileRoutingLogic {
    private let screenRouter: ScreenNavigator
    private let toastPresenter: ToastPresenting

    weak var viewController: UIViewController?

    init(
        screenRouter: ScreenNavigator,
        toastPresenter: ToastPresenting
    ) {
        self.screenRouter = screenRouter
        self.toastPresenter = toastPresenter
    }

    func openConfirmation(context: CommonConfirmationContext) {
        let container = viewController?.navigationController ?? viewController
        let confirmationScreen = CommonConfirmationFactory(
            context: context
        )
        .withBottomSheet(.init(detents: [.content]))

        screenRouter.navigate(from: container) { route in
            route.present(confirmationScreen)
        }
    }

    func openCurrencySelection(
        currentCurrencyCode: String,
        output: ProfileCurrencySelectionOutput
    ) {
        let currencyScreen = ProfileCurrencyFactory(
            currentCurrencyCode: currentCurrencyCode,
            output: output
        )
        .withStackContainer()
        .withModalPresentationStyle(.pageSheet)

        screenRouter.navigate(to: { route in
            route
                .top(.stack)
                .present(currencyScreen)
        })
    }

    func openSubscription(
        currentTier: String,
        output: SubscriptionOutput
    ) {
        let subscriptionScreen = SubscriptionFactory(
            currentTier: currentTier,
            output: output
        )
            .withModalPresentationStyle(.pageSheet)

        screenRouter.navigate { route in
            route
                .top(.stack)
                .present(subscriptionScreen)
        }
    }

    func presentError(with text: String) {
        toastPresenter.present(state: .error, title: text)
    }
}
