// Created by Egor Shkarin 25.03.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol ExpesiesListRoutingLogic: Sendable {
    func presentError(with text: String)
}

final class ExpesiesListRouter: ExpesiesListRoutingLogic {
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
}
