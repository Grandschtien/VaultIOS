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

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: scene)
        let navigator = ScreenNavigator(window: window)
        let coordinator = AppCoordinator(
            screenNavigator: navigator,
            appAssebler: DI.assembler,
            isLoggedIn: false
        )

        self.window = window
        self.appCoordinator = coordinator

        coordinator.start()
    }
}
