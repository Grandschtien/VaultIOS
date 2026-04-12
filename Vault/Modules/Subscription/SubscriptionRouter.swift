// Created by Egor Shkarin 08.04.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol SubscriptionRoutingLogic: Sendable {
    func close()
    func presentError(with text: String)
    func presentMessage(with text: String)
}

final class SubscriptionRouter: SubscriptionRoutingLogic {
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

    func close() {
        let container = viewController?.navigationController ?? viewController

        screenRouter.navigate(from: container) { route in
            route.dimiss()
        }
    }

    func presentError(with text: String) {
        toastPresenter.present(
            state: .error,
            title: SubscriptionToastMessageSanitizer.sanitize(text)
        )
    }

    func presentMessage(with text: String) {
        toastPresenter.present(
            state: .neutral,
            title: SubscriptionToastMessageSanitizer.sanitize(text)
        )
    }
}
