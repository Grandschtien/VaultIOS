//
//  AppCoordinator.swift
//  Vault
//
//  Created by Егор Шкарин on 14.03.2026.
//

import UIKit
import Nivelir

@MainActor
final class AppCoordinator {
    private let screenNavigator: ScreenNavigator
    private let isLoggedIn: Bool
    private let rootViewController: RootViewController
    
    @UserDefault(.isOnboardingCompleted, default: false)
    var isOnboardingShown: Bool

    init(
        screenNavigator: ScreenNavigator,
        isLoggedIn: Bool
    ) {
        self.screenNavigator = screenNavigator
        self.isLoggedIn = isLoggedIn
        self.rootViewController = RootViewController()
    }

    func start() {
        screenNavigator.navigate { route in
            route
                .setRoot(to: rootViewController)
                .makeKeyAndVisible()
        }

        routeToInitialFlow()
    }
}

private extension AppCoordinator {
    func routeToInitialFlow() {
        if isLoggedIn {
            showMainFlow()
        } else if isOnboardingShown {
            showAuthFlow()
        } else {
            showOnboardingFlow()
        }
    }

    func showOnboardingFlow() {
        let onboardingController = OnboardingFactory(output: self).build(
            navigator: screenNavigator
        )
        rootViewController.setRoot(onboardingController)
    }

    func showAuthFlow() {
        let loginController = LoginFactory().build(navigator: screenNavigator)
        let navigationController = UINavigationController(rootViewController: loginController)
        rootViewController.setRoot(navigationController)
    }

    func showMainFlow() {
        rootViewController.setRoot(makeMainTabBarController())
    }

    func makeMainTabBarController() -> UITabBarController {
        return UITabBarController()
    }
}

// MARK: - OnboardingFlowOutput
extension AppCoordinator: OnboardingFlowOutput {
    func didFinishOnboarding() {
        isOnboardingShown = true
        showAuthFlow()
    }
}
