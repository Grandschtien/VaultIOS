import UIKit
import Foundation
import Nivelir

@MainActor
protocol AnalyticsRoutingLogic: Sendable {
    func openCategory(id: String, name: String)
    func openPeriodPicker(
        selectedFromDate: Date,
        selectedToDate: Date,
        output: CategoryPeriodPickerOutput
    )
}

final class AnalyticsRouter: AnalyticsRoutingLogic {
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
