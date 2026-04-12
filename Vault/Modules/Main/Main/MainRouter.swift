// Created by Egor Shkarin 23.03.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol MainRoutingLogic: Sendable {
    func openAllCategories()
    func openAllExpenses()
    func openCategory(id: String, name: String)
    func openSubscription(
        currentTier: String,
        output: SubscriptionOutput
    )
    func openPeriodPicker(
        selectedFromDate: Date,
        selectedToDate: Date,
        output: CategoryPeriodPickerOutput
    )
}

final class MainRouter: MainRoutingLogic {
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

    func openAllCategories() {
        screenRouter.navigate(to: { route in
            route
                .top(.stack)
                .push(CategoriesListFactory(context: context))
        })
    }

    func openAllExpenses() {
        screenRouter.navigate(to: { route in
            route
                .top(.stack)
                .push(ExpesiesListFactory(context: context))
        })
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

    func openSubscription(
        currentTier: String,
        output: SubscriptionOutput
    ) {
        guard let viewController else {
            return
        }

        screenRouter.navigate(from: viewController) { route in
            route.present(
                SubscriptionFactory(
                    currentTier: currentTier,
                    output: output
                )
                .withModalPresentationStyle(.pageSheet)
            )
        }
    }

    func openPeriodPicker(
        selectedFromDate: Date,
        selectedToDate: Date,
        output: CategoryPeriodPickerOutput
    ) {
        guard let viewController else {
            return
        }

        screenRouter.navigate(from: viewController) { route in
            route.present(
                CategoryPeriodPickerFactory(
                    selectedFromDate: selectedFromDate,
                    selectedToDate: selectedToDate,
                    output: output
                )
                .withStackContainer()
                .withModalPresentationStyle(.pageSheet)
            )
        }
    }
}
