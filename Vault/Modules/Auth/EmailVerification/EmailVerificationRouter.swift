import Foundation
import Nivelir

@MainActor
protocol EmailVerificationRoutingLogic: Sendable {
    func openMainFlow()
    func presentError(with text: String)
}

final class EmailVerificationRouter: EmailVerificationRoutingLogic {
    private let screenRouter: ScreenNavigator
    private let toastPresenter: ToastPresenting

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
