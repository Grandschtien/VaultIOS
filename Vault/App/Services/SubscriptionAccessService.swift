// Created by Egor Shkarin 11.04.2026

import Foundation

enum SubscriptionTierState: Equatable, Sendable {
    case resolved(String)
    case unavailable

    var tier: String {
        switch self {
        case .resolved(let tier):
            tier
        case .unavailable:
            "REGULAR"
        }
    }
}

protocol SubscriptionAccessServicing: Sendable {
    func currentTierState() async -> SubscriptionTierState
    func refreshCurrentTierState() async -> SubscriptionTierState
}

extension SubscriptionAccessServicing {
    func currentTier() async -> String {
        await currentTierState().tier
    }

    func refreshCurrentTier() async -> String {
        await refreshCurrentTierState().tier
    }
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

    func currentTierState() async -> SubscriptionTierState {
        await resolvedTierState(forceRefresh: false)
    }

    func refreshCurrentTierState() async -> SubscriptionTierState {
        await resolvedTierState(forceRefresh: true)
    }
}

private extension SubscriptionAccessService {
    func resolvedTierState(forceRefresh: Bool) async -> SubscriptionTierState {
        guard let userID = currentUserID() else {
            await state.clear()
            return .resolved(Constants.regularTier)
        }

        if !forceRefresh,
           let cachedTier = await state.cachedTier(for: userID) {
            return .resolved(cachedTier)
        }

        do {
            let profile = try await resolvedProfile(forceRefresh: forceRefresh)
            let tier = normalizedTier(profile.tier)
            await state.setCachedTier(tier, for: profile.id)
            return .resolved(tier)
        } catch {
            if let cachedTier = await state.cachedTier(for: userID) {
                return .resolved(cachedTier)
            }

            return .unavailable
        }
    }

    func currentUserID() -> String? {
        let userID = (userProfileStorageService.loadProfile()?.userId ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return userID.isEmpty ? nil : userID
    }

    func resolvedProfile(forceRefresh: Bool) async throws -> ProfileResponseDTO {
        if forceRefresh {
            return try await profileService.refreshProfile()
        }

        return try await profileService.getProfile()
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
