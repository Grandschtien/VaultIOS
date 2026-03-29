// Created by Egor Shkarin 23.03.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol MainRoutingLogic: Sendable {
    func openAllCategories()
    func openAllExpenses()
    func openCategory(id: String, name: String)
}

final class MainRouter: MainRoutingLogic {
    private let screenRouter: ScreenNavigator
    private let dataStoreCache: MainDataStoreCache

    weak var viewController: UIViewController?

    init(
        screenRouter: ScreenNavigator,
        dataStoreCache: MainDataStoreCache
    ) {
        self.screenRouter = screenRouter
        self.dataStoreCache = dataStoreCache
    }

    func openAllCategories() {
        screenRouter.navigate(to: { route in
            route
                .top(.stack)
                .push(CategoriesListFactory(dataStoreCache: dataStoreCache))
        })
    }

    func openAllExpenses() {
        screenRouter.navigate(to: { route in
            route
                .top(.stack)
                .push(ExpesiesListFactory())
        })
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
