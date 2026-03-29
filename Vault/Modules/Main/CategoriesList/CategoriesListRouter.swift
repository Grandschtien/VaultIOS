// Created by Egor Shkarin on 27.03.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol CategoriesListRoutingLogic: Sendable {
    func openCategory(id: String, name: String)
}

final class CategoriesListRouter: CategoriesListRoutingLogic {
    private let screenRouter: ScreenNavigator

    weak var viewController: UIViewController?

    init(screenRouter: ScreenNavigator) {
        self.screenRouter = screenRouter
    }

    func openCategory(id: String, name: String) {
        screenRouter.navigate(to: { route in
            route
                .top(.stack)
                .push(
                    CategoryFactory(
                        categoryID: id,
                        categoryName: name
                    )
                )
        })
    }
}
