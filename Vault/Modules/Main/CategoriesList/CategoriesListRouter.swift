// Created by Egor Shkarin on 27.03.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol CategoriesListRoutingLogic: Sendable {
    func openCategory(id: String, name: String)
    func openCategoryCreate()
}

final class CategoriesListRouter: CategoriesListRoutingLogic {
    private let screenRouter: ScreenNavigator
    private let context: MainFlowContext

    weak var viewController: UIViewController?

    init(
        screenRouter: ScreenNavigator,
        context: MainFlowContext
    ) {
        self.screenRouter = screenRouter
        self.context = context
    }

    func openCategory(id: String, name: String) {
        screenRouter.navigate(to: { route in
            route
                .top(.stack)
                .push(
                    CategoryFactory(
                        categoryID: id,
                        categoryName: name,
                        context: context
                    )
                )
        })
    }

    func openCategoryCreate() {
        screenRouter.navigate(to: { route in
            route
                .top(.stack)
                .push(
                    CategoryEditorFactory(
                        mode: .create,
                        context: context
                    )
                )
        })
    }
}
