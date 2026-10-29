import Foundation
@testable import Vylok

enum UserProfileDefaultsFixtures {
    static func makeProfile(
        userId: String = "1",
        email: String = "name@example.com",
        name: String = "Egor",
        currency: String = "USD",
        language: String = "en-US",
        currencyRate: Double? = nil,
        currencyRateUpdatedAt: Date? = nil,
        cachedSubscription: SubscriptionAccessSnapshot? = nil,
        cachedAIParseUsage: AIParseUsageDTO? = nil
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
}
