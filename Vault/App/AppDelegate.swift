//
//  AppDelegate.swift
//  Vault
//
//  Created by Егор Шкарин on 01.02.2026.
//

import FirebaseAnalytics
import FirebaseCore
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()

        if LaunchEnvironmentProvider.shared.isQAMode {
            Analytics.setAnalyticsCollectionEnabled(false)
        }

        return true
    }
}

