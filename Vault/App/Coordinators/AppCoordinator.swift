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
    
    @UserDefault(.isOnboardingCompleted, default: false)
    var isOnboardingShown: Bool

    init(
        screenNavigator: ScreenNavigator,
        appAssebler: Assembler,
        isLoggedIn: Bool
    ) {
        self.screenNavigator = screenNavigator
        self.isLoggedIn = isLoggedIn
        self.appAssebler = appAssebler
    }

    func start() {
        appAssebler.apply(assembly: AppAssembly())
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
        ) as! OnboardingViewController

        screenNavigator.navigate { route in
            route
                .setRoot(to: onboardingController)
                .makeKeyAndVisible()
        }
    }

    func showAuthFlow() {
        let loginController = LoginFactory().build(navigator: screenNavigator)
        let root = RootAuthViewController(rootViewController: loginController)
        root.setNavigationBarHidden(true, animated: false)

        screenNavigator.navigate { route in
            route
                .setRoot(to: root)
                .makeKeyAndVisible()
        }
    }

    func showMainFlow() {
        let root = MainFlowRootViewController()

        screenNavigator.navigate { route in
            route
                .setRoot(to: root)
                .makeKeyAndVisible()
        }
    }
}
// MARK: - OnboardingFlowOutput
extension AppCoordinator: OnboardingFlowOutput {
    func didFinishOnboarding() {
        isOnboardingShown = true
        showAuthFlow()
    }
}
