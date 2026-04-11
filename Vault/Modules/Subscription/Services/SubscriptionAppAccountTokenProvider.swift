// Created by Egor Shkarin 09.04.2026

import Foundation

protocol SubscriptionAppAccountTokenProviding: Sendable {
    func currentAppAccountToken() throws -> UUID
}

final class SubscriptionAppAccountTokenProvider: SubscriptionAppAccountTokenProviding {
    private let userProfileStorageService: UserProfileStorageServiceProtocol

    init(userProfileStorageService: UserProfileStorageServiceProtocol) {
        self.userProfileStorageService = userProfileStorageService
    }

    func currentAppAccountToken() throws -> UUID {
        let userID = userProfileStorageService.loadProfile()?
            .userId
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let userID, !userID.isEmpty, let appAccountToken = UUID(uuidString: userID) else {
            throw SubscriptionAppAccountTokenProviderError.unavailable
        }

        return appAccountToken
    }
}

enum SubscriptionAppAccountTokenProviderError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        L10n.subscriptionAccountTokenUnavailable
    }
}
