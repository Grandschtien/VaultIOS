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
        AppLogBridge.install(service: appAssebler.resolver.resolve(AppLogServiceProtocol.self))
        AppLogBridge.log(category: .app, name: "start", source: "AppCoordinator")
        appAssebler.resolver.resolve(FirstRunKeychainCleanupServiceProtocol.self)?
            .clearKeychainIfNeeded()
        appAssebler.resolver.resolve(SubscriptionAccessServicing.self)?.startMonitoring()
        observeLogoutEvents()
        
        Task {
            await appAssebler.resolver.resolve(SubscriptionInitializerLogic.self)!.initialize()
            appAssebler.resolver.resolve(SubscriptionUpdatesListenerLogic.self)!.start()
        }

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

        let hasValidSession = await authSessionService.hasValidSession()
        AppLogBridge.log(
            category: .app,
            name: "initial_flow_resolved",
            source: "AppCoordinator",
            payload: ["has_valid_session": hasValidSession]
        )

        if hasValidSession {
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
                AppLogBridge.log(
                    category: .navigation,
                    name: "logout_route_to_auth",
                    source: "AppCoordinator"
                )
                self?.showAuthFlow()
            }
        }
    }

    func showOnboardingFlow() {
        AppLogBridge.log(
            category: .navigation,
            name: "show_onboarding_flow",
            source: "AppCoordinator"
        )
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
        AppLogBridge.log(
            category: .navigation,
            name: "show_auth_flow",
            source: "AppCoordinator"
        )
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
        AppLogBridge.log(
            category: .navigation,
            name: "show_main_flow",
            source: "AppCoordinator"
        )
        screenNavigator.navigate { route in
            route
                .setRoot(to: MainFlowRootFactory())
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
