// Created by Egor Shkarin 14.03.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol LoginRoutingLogic: Sendable {
    func openRegistration()
    func openEmailVerification(context: EmailVerificationContext)
    func openMainFlow()
    func openForgetPasswordScreen(context: ForgotPasswordContext)
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

    func openEmailVerification(context: EmailVerificationContext) {
        screenRouter.navigate(to: { route in
            route
                .top(.stack)
                .push(EmailVerificationFactory(context: context))
        })
    }

    func openMainFlow() {
        screenRouter.navigate(to: { route in
            route
                .setRoot(to: MainFlowRootFactory())
                .makeKeyAndVisible()
        })
    }

    func openForgetPasswordScreen(context: ForgotPasswordContext) {
        let forgotPasswordScreen = ForgotPasswordFactory(context: context)
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
