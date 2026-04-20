//
//  SubscriptionInitializer.swift
//  Vault
//
//  Created by Егор Шкарин on 20.04.2026.
//

import Foundation
import RevenueCat

protocol SubscriptionInitializerLogic {
    func initialize() async
    func setUserId(_ id: String) async
    func logout() async
}

actor SubscriptionInitializer: SubscriptionInitializerLogic {

    private let apiKey: String
    private var isInitialized = false
    private let profileService: ProfileContractServicing

    init(
        apiKey: String,
        profileService: ProfileContractServicing
    ) {
        self.apiKey = apiKey
        self.profileService = profileService
    }

    func initialize() async {
        guard !isInitialized else { return }

        Purchases.logLevel = currentLogLevel()

        if let savedUderId = try? await profileService.getProfile().id {
            Purchases.configure(
                withAPIKey: apiKey,
                appUserID: savedUderId
            )
        } else {
            Purchases.configure(withAPIKey: apiKey)
        }

        isInitialized = true
    }

    func setUserId(_ id: String) async {
        if isInitialized {
            do {
                _ = try await Purchases.shared.logIn(id)
            } catch {
                assertionFailure("RevenueCat logIn failed: \(error)")
            }
        } else {
            assertionFailure("RevenueCat is not initialized")
        }
    }

    func logout() async {
        guard isInitialized else { return }

        do {
            _ = try await Purchases.shared.logOut()
        } catch {
            assertionFailure("RevenueCat logOut failed: \(error)")
        }
    }

    private nonisolated func currentLogLevel() -> LogLevel {
        #if DEBUG
        return .debug
        #else
        return .error
        #endif
    }
}
