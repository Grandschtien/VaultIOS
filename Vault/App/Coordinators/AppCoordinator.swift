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
    private let screenNavigator: ScreenNavigator
    private let appAssebler: Assembler
    private var logoutObserver: NSObjectProtocol?
    
    @UserDefault(.isOnboardingCompleted, default: false)
    var isOnboardingShown: Bool

    init(
        screenNavigator: ScreenNavigator,
        appAssebler: Assembler
    ) {
        self.screenNavigator = screenNavigator
        self.appAssebler = appAssebler
    }

    func start() {
        appAssebler.apply(assembly: AppAssembly())
        appAssebler.resolver.resolve(FirstRunKeychainCleanupServiceProtocol.self)?
            .clearKeychainIfNeeded()
        observeLogoutEvents()

        Task { [weak self] in
            await self?.routeToInitialFlow()
        }
    }

    deinit {
        if let logoutObserver {
            NotificationCenter.default.removeObserver(logoutObserver)
        }
    }
}

private extension AppCoordinator {
    func routeToInitialFlow() async {
        if !isOnboardingShown {
            showOnboardingFlow()
            return
        }

        guard let authSessionService = appAssebler.resolver.resolve(AuthSessionServiceProtocol.self) else {
            showAuthFlow()
            return
        }

        if await authSessionService.hasValidSession() {
            showMainFlow()
        } else {
            showAuthFlow()
        }
    }

    func observeLogoutEvents() {
        logoutObserver = NotificationCenter.default.addObserver(
            forName: .authSessionDidLogout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.showAuthFlow()
            }
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
        let root = MainFlowRootViewController(screenNavigator: screenNavigator)

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
