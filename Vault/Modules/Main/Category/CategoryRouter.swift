// Created by Egor Shkarin on 28.03.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol CategoryRoutingLogic: Sendable {
    func presentError(with text: String)
    func close()
}

final class CategoryRouter: CategoryRoutingLogic {
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

    func presentError(with text: String) {
        toastPresenter.present(state: .error, title: text)
    }

    func close() {
        if let navigationController = viewController?.navigationController {
            screenRouter.navigate(from: navigationController) { route in
                route.pop()
            }
            return
        }

        screenRouter.navigate(from: viewController) { route in
            route.dimiss()
        }
    }
}
