import UIKit
import Nivelir

@MainActor
protocol ExpenseAIEntryRoutingLogic: Sendable {
    func close()
    func presentComingSoon()
}

final class ExpenseAIEntryRouter: ExpenseAIEntryRoutingLogic {
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
            route.presenting { presentingRoute in
                presentingRoute.dismiss()
            }
        }
    }

    func presentComingSoon() {
        toastPresenter.present(state: .neuteral, title: L10n.mainOverviewComingSoon)
    }
}
