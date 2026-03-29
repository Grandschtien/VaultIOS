// Created by Egor Shkarin on 28.03.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol CategoryRoutingLogic: Sendable {
    func openCategoryEdit(id: String, name: String)
    func presentError(with text: String)
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

    func openCategoryEdit(id: String, name: String) { }

    func presentError(with text: String) {
        toastPresenter.present(state: .error, title: text)
    }
}
