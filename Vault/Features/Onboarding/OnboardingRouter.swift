// Created by Egor Shkarin 11.03.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol OnboardingRoutingLogic: Sendable {
    func routeToNextScreen()
}

final class OnboardingRouter: OnboardingRoutingLogic {
    private let screenRouter: ScreenNavigator

    init(screenRouter: ScreenNavigator) {
        self.screenRouter = screenRouter
    }

    func routeToNextScreen() {
        screenRouter.navigate { route in
            route
                .setRoot(to: OnboardingNextScreen())
                .makeKeyAndVisible()
        }
    }
}

private struct OnboardingNextScreen: Screen {
    func build(navigator: ScreenNavigator) -> UIViewController {
        ViewController()
    }
}
