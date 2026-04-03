// Created by Egor Shkarin 29.03.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol ProfileRoutingLogic: Sendable {
    func openCurrencySelection(
        currentCurrencyCode: String,
        output: ProfileCurrencySelectionOutput
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

    func presentError(with text: String) {
        toastPresenter.present(state: .error, title: text)
    }
}
