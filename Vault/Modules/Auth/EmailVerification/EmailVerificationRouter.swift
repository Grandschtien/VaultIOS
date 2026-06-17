import Foundation
import Nivelir
import UIKit

@MainActor
protocol EmailVerificationRoutingLogic: Sendable {
    func close()
    func openMainFlow()
    func presentError(with text: String)
}

final class EmailVerificationRouter: EmailVerificationRoutingLogic {
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
