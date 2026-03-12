//
//  SceneDelegate.swift
//  Vault
//
//  Created by Егор Шкарин on 01.02.2026.
//

import UIKit
import Nivelir

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var screenNavigator: ScreenNavigator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: scene)
        let navigator = ScreenNavigator(window: window)

        self.window = window
        self.screenNavigator = navigator

        navigator.navigate { route in
            route
                .setRoot(to: OnboardingFactory())
                .makeKeyAndVisible()
        }
    }
}
