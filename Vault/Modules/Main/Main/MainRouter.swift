// Created by Egor Shkarin 23.03.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol MainRoutingLogic: Sendable {
    func openAllCategories()
    func openAllExpenses()
}

final class MainRouter: MainRoutingLogic {
    private let screenRouter: ScreenNavigator

    weak var viewController: UIViewController?

    init(screenRouter: ScreenNavigator) {
        self.screenRouter = screenRouter
    }

    func openAllCategories() {
        screenRouter.navigate(to: { route in
            route
                .top(.stack)
                .push(MainComingSoonFactory(title: L10n.mainOverviewCategories))
        })
    }

    func openAllExpenses() {
        screenRouter.navigate(to: { route in
            route
                .top(.stack)
                .push(MainComingSoonFactory(title: L10n.mainOverviewRecentExpenses))
        })
    }
}

private struct MainComingSoonFactory: Screen {
    let title: String

    func build(navigator: ScreenNavigator) -> UIViewController {
        let viewController = UIViewController()
        viewController.title = title
        viewController.view.backgroundColor = Asset.Colors.backgroundPrimary.color

        let label = Label()
        label.apply(
            .init(
                text: L10n.mainOverviewComingSoon,
                font: Typography.typographyMedium16,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .center
            )
        )

        viewController.view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])

        return viewController
    }
}
