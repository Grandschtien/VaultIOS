// Created by Egor Shkarin 11.04.2026

import Foundation

protocol SubscriptionAccessServicing: Sendable {
    func currentTier() async -> String
    func refreshCurrentTier() async -> String
}

final class SubscriptionAccessService: SubscriptionAccessServicing, @unchecked Sendable {
    private enum Constants {
        static let regularTier = "REGULAR"
    }

    private let profileService: ProfileContractServicing
    private let userProfileStorageService: UserProfileStorageServiceProtocol
    private let state = State()

    private var logoutObserver: NSObjectProtocol?

    init(
        profileService: ProfileContractServicing,
        userProfileStorageService: UserProfileStorageServiceProtocol
    ) {
        self.profileService = profileService
        self.userProfileStorageService = userProfileStorageService

        logoutObserver = NotificationCenter.default.addObserver(
            forName: .authSessionDidLogout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.state.clear()
            }
        }
    }

    deinit {
        if let logoutObserver {
            NotificationCenter.default.removeObserver(logoutObserver)
        }
    }

    func currentTier() async -> String {
        await resolvedTier(forceRefresh: false)
    }

    func refreshCurrentTier() async -> String {
        await resolvedTier(forceRefresh: true)
    }
}

private extension SubscriptionAccessService {
    func resolvedTier(forceRefresh: Bool) async -> String {
        guard let userID = currentUserID() else {
            await state.clear()
            return Constants.regularTier
        }

        if !forceRefresh,
           let cachedTier = await state.cachedTier(for: userID) {
            return cachedTier
        }

        do {
            let profile = try await profileService.getProfile()
            let tier = normalizedTier(profile.tier)
            await state.setCachedTier(tier, for: profile.id)
            return tier
        } catch {
            if let cachedTier = await state.cachedTier(for: userID) {
                return cachedTier
            }

            return Constants.regularTier
        }
    }

    func currentUserID() -> String? {
        let userID = (userProfileStorageService.loadProfile()?.userId ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return userID.isEmpty ? nil : userID
    }

    func normalizedTier(_ tier: String) -> String {
        let normalized = tier
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        return normalized.isEmpty ? Constants.regularTier : normalized
    }
}

private extension SubscriptionAccessService {
    actor State {
        private var cachedTierByUserID: [String: String] = [:]

        func cachedTier(for userID: String) -> String? {
            cachedTierByUserID[userID]
        }

        func setCachedTier(_ tier: String, for userID: String) {
            cachedTierByUserID[userID] = tier
        }

        func clear() {
            cachedTierByUserID = [:]
        }
    }
}
