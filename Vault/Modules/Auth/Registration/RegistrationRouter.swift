// Created by Egor Shkarin 16.03.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol RegistrationRoutingLogic: Sendable {
    func openMainFlow()
    func presentError(with text: String)
}

final class RegistrationRouter: RegistrationRoutingLogic {
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

    func openMainFlow() {
        screenRouter.navigate(to: { route in
            route
                .setRoot(to: MainFlowRootFactory())
                .makeKeyAndVisible()
        })
    }

    func presentError(with text: String) {
        toastPresenter.present(state: .error, title: text)
    }
}
