// Created by Egor Shkarin 14.03.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol LoginRoutingLogic: Sendable {
    func openRegistration()
    func openMainFlow()
    func openForgetPasswordScreen()
    func presentError(with text: String)
}

final class LoginRouter: LoginRoutingLogic {
    private let screenRouter: ScreenNavigator
    private let toastPresenter: ToastPresenting

    init(
        screenRouter: ScreenNavigator,
        toastPresenter: ToastPresenting
    ) {
        self.screenRouter = screenRouter
        self.toastPresenter = toastPresenter
    }

    func openRegistration() {
        screenRouter.navigate(to: { route in
            route
                .top(.stack)
                .push(RegistrationFactory())
        })
    }

    func openMainFlow() {
        screenRouter.navigate(to: { route in
            route
                .setRoot(to: MainFlowRootFactory())
                .makeKeyAndVisible()
        })
    }

    func openForgetPasswordScreen() {
        let forgotPasswordScreen = ForgotPasswordFactory()
            .withBottomSheet(.init(detents: [.content]))

        screenRouter.navigate(to: { route in
            route
                .top(.stack)
                .present(forgotPasswordScreen)
        })
    }

    func presentError(with text: String) {
        toastPresenter.present(state: .error, title: text)
    }
}
