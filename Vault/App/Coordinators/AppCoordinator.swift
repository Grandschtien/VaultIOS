//
//  AppCoordinator.swift
//  Vault
//
//  Created by Егор Шкарин on 14.03.2026.
//

import UIKit
import Swinject
import Nivelir

@MainActor
final class AppCoordinator {
    private let isLoggedIn: Bool
    private let screenNavigator: ScreenNavigator
    private let appAssebler: Assembler
    private let rootViewController: RootViewController
    
    @UserDefault(.isOnboardingCompleted, default: false)
    var isOnboardingShown: Bool

    init(
        screenNavigator: ScreenNavigator,
        appAssebler: Assembler,
        isLoggedIn: Bool
    ) {
        self.screenNavigator = screenNavigator
        self.isLoggedIn = isLoggedIn
        self.rootViewController = RootViewController()
        self.appAssebler = appAssebler
    }

    func start() {
        appAssebler.apply(assembly: AppAssembly())
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
