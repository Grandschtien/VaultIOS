// Created by Egor Shkarin 08.04.2026

import Foundation

struct SubscriptionCatalogPlan: Equatable, Sendable {
    let id: String
    let title: String
}

enum SubscriptionCatalog {
    static let plus = SubscriptionCatalogPlan(
        id: "vault.subscription.plus",
        title: L10n.subscriptionPlus
    )
    static let premium = SubscriptionCatalogPlan(
        id: "vault.subscription.premium",
        title: L10n.subscriptionPremium
    )

    static let orderedPlans: [SubscriptionCatalogPlan] = [plus, premium]

    static func title(for id: String) -> String {
        orderedPlans.first(where: { $0.id == id })?.title ?? id
    }
}
