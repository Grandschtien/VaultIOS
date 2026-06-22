//
//  SceneDelegate.swift
//  Vault
//
//  Created by Егор Шкарин on 01.02.2026.
//

import UIKit
import Swinject
import Nivelir

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let scene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = .light
        let navigator = ScreenNavigator(window: window)
        let coordinator = AppCoordinator(
            screenNavigator: navigator,
            appAssebler: DI.assembler
        )

        self.window = window
        self.appCoordinator = coordinator

        coordinator.start()
        handleURLContexts(connectionOptions.urlContexts)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        handleURLContexts(URLContexts)
    }
}

private extension SceneDelegate {
    func handleURLContexts(_ urlContexts: Set<UIOpenURLContext>) {
        guard let parser = DI.assembler.resolver.resolve(VaultRouteParsing.self),
              let store = DI.assembler.resolver.resolve(PendingVaultRouteStoring.self) else {
            return
        }

        urlContexts
            .compactMap { parser.parse(url: $0.url) }
            .forEach(store.store)
    }
}
