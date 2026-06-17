// Created by Egor Shkarin on 28.03.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol CategoryRoutingLogic: Sendable {
    func presentError(with text: String)
    func openCategoryEdit(id: String)
    func close()
}

final class CategoryRouter: CategoryRoutingLogic {
    private let screenRouter: ScreenNavigator
    private let context: MainFlowContext
    private let toastPresenter: ToastPresenting

    weak var viewController: UIViewController?

    init(
        screenRouter: ScreenNavigator,
        context: MainFlowContext,
        toastPresenter: ToastPresenting
    ) {
        self.screenRouter = screenRouter
        self.context = context
        self.toastPresenter = toastPresenter
    }

    func presentError(with text: String) {
        toastPresenter.present(state: .error, title: text)
    }

    func openCategoryEdit(id: String) {
        screenRouter.navigate(to: { route in
            route
                .top(.stack)
                .push(
                    CategoryEditorFactory(
                        mode: .edit(id: id),
                        context: context
                    )
                )
        })
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
