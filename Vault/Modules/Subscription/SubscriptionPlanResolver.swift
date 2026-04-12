// Created by Egor Shkarin 11.04.2026

import Foundation

struct SubscriptionResolvedPlan: Equatable, Sendable {
    let title: String
    let description: String
}

enum SubscriptionPlanResolver {
    static func hasPremiumAccess(for rawTier: String) -> Bool {
        currentProductID(from: rawTier) != nil
    }

    static func hasPremiumTier(for rawTier: String) -> Bool {
        if case .premium = normalizedTier(from: rawTier) {
            return true
        }

        return false
    }

    static func description(for productID: String) -> String {
        switch productID {
        case SubscriptionCatalog.plus.id:
            L10n.subscriptionPlusDescription
        case SubscriptionCatalog.premium.id:
            L10n.subscriptionPremiumDescription
        default:
            L10n.subscriptionUnknownDescription
        }
    }

    static func currentPlan(from rawTier: String) -> SubscriptionResolvedPlan {
        switch normalizedTier(from: rawTier) {
        case .free:
            SubscriptionResolvedPlan(
                title: L10n.subscriptionFree,
                description: L10n.subscriptionFreeDescription
            )
        case .plus:
            SubscriptionResolvedPlan(
                title: L10n.subscriptionPlus,
                description: L10n.subscriptionPlusDescription
            )
        case .premium:
            SubscriptionResolvedPlan(
                title: L10n.subscriptionPremium,
                description: L10n.subscriptionPremiumDescription
            )
        case let .unknown(title):
            SubscriptionResolvedPlan(
                title: title,
                description: L10n.subscriptionUnknownDescription
            )
        }
    }

    static func currentProductID(from rawTier: String) -> String? {
        switch normalizedTier(from: rawTier) {
        case .plus:
            SubscriptionCatalog.plus.id
        case .premium:
            SubscriptionCatalog.premium.id
        case .free, .unknown:
            nil
        }
    }
}

private extension SubscriptionPlanResolver {
    enum Tier {
        case free
        case plus
        case premium
        case unknown(String)
    }

    static func normalizedTier(from rawTier: String) -> Tier {
        let normalized = rawTier
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard !normalized.isEmpty else {
            return .free
        }

        if normalized.contains("PREMIUM") {
            return .premium
        }

        if normalized.contains("PLUS") || normalized == "ACTIVE" {
            return .plus
        }

        if normalized.contains("FREE") || normalized.contains("REGULAR") {
            return .free
        }

        return .unknown(displayTitle(from: normalized))
    }

    static func displayTitle(from normalizedTier: String) -> String {
        normalizedTier
            .replacingOccurrences(of: "_", with: " ")
            .lowercased()
            .split(separator: " ")
            .map(\.capitalized)
            .joined(separator: " ")
    }
}
