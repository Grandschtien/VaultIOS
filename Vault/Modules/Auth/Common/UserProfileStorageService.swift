//
//  UserProfileStorageService.swift
//  Vault
//
//  Created by Egor Shkarin on 25.03.2026.
//

import Foundation

struct UserProfileDefaults: Codable, Equatable, Sendable {
    let userId: String
    let email: String
    let name: String
    let currency: String
    let language: String
    let currencyRate: Double?
    let currencyRateUpdatedAt: Date?
    let cachedSubscription: SubscriptionAccessSnapshot?
    let cachedAIParseUsage: AIParseUsageDTO?

    init(
        userId: String,
        email: String,
        name: String,
        currency: String,
        language: String,
        currencyRate: Double? = nil,
        currencyRateUpdatedAt: Date? = nil,
        cachedSubscription: SubscriptionAccessSnapshot? = nil,
        cachedAIParseUsage: AIParseUsageDTO? = nil
    ) {
        self.userId = userId
        self.email = email
        self.name = name
        self.currency = currency
        self.language = language
        self.currencyRate = currencyRate
        self.currencyRateUpdatedAt = currencyRateUpdatedAt
        self.cachedSubscription = cachedSubscription
        self.cachedAIParseUsage = cachedAIParseUsage
    }
}

protocol UserProfileStorageServiceProtocol: Sendable {
    func saveProfile(_ profile: UserProfileDefaults)
    func loadProfile() -> UserProfileDefaults?
    func clearProfile()
}

final class UserProfileStorageService: UserProfileStorageServiceProtocol, @unchecked Sendable {
    private enum Constants {
        static let profileKey: String = "auth.profile.defaults"
    }

    private let storage: KeyValueStorage

    init(storage: KeyValueStorage = UserDefaultsStorage()) {
        self.storage = storage
    }

    func saveProfile(_ profile: UserProfileDefaults) {
        storage.set(profile, forKey: Constants.profileKey)
    }

    func loadProfile() -> UserProfileDefaults? {
        storage.get(UserProfileDefaults.self, forKey: Constants.profileKey)
    }

    func clearProfile() {
        storage.removeValue(forKey: Constants.profileKey)
    }
}

extension UserProfileDefaults {
    init(
        user: User,
        cachedSubscription: SubscriptionAccessSnapshot? = nil
    ) {
        self.init(
            userId: user.id,
            email: user.email,
            name: user.name,
            currency: user.currency,
            language: user.preferredLanguage,
            cachedSubscription: cachedSubscription
        )
    }

    func withCurrencyRate(
        _ rate: Double,
        updatedAt: Date
    ) -> UserProfileDefaults {
        UserProfileDefaults(
            userId: userId,
            email: email,
            name: name,
            currency: currency,
            language: language,
            currencyRate: rate,
            currencyRateUpdatedAt: updatedAt,
            cachedSubscription: cachedSubscription,
            cachedAIParseUsage: cachedAIParseUsage
        )
    }

    func withCachedSubscription(
        _ cachedSubscription: SubscriptionAccessSnapshot?
    ) -> UserProfileDefaults {
        UserProfileDefaults(
            userId: userId,
            email: email,
            name: name,
            currency: currency,
            language: language,
            currencyRate: currencyRate,
            currencyRateUpdatedAt: currencyRateUpdatedAt,
            cachedSubscription: cachedSubscription,
            cachedAIParseUsage: cachedAIParseUsage
        )
    }

    func withCachedAIParseUsage(_ cachedAIParseUsage: AIParseUsageDTO?) -> UserProfileDefaults {
        UserProfileDefaults(
            userId: userId,
            email: email,
            name: name,
            currency: currency,
            language: language,
            currencyRate: currencyRate,
            currencyRateUpdatedAt: currencyRateUpdatedAt,
            cachedSubscription: cachedSubscription,
            cachedAIParseUsage: cachedAIParseUsage
        )
    }
}
