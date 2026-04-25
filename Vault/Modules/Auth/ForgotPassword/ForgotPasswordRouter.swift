import UIKit
import Foundation
import Nivelir

@MainActor
protocol ForgotPasswordRoutingLogic: Sendable {
    func close()
    func presentSuccess(with text: String)
    func presentError(with text: String)
}

final class ForgotPasswordRouter: ForgotPasswordRoutingLogic {
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
        if let navigationController = viewController?.navigationController,
           navigationController.viewControllers.count > 1 {
            screenRouter.navigate(from: navigationController) { route in
                route.pop()
            }
            return
        }

        screenRouter.navigate(from: viewController) { route in
            route.dimiss()
        }
    }

    func presentSuccess(with text: String) {
        toastPresenter.present(state: .success, title: text)
    }

    func presentError(with text: String) {
        toastPresenter.present(state: .error, title: text)
    }
}
