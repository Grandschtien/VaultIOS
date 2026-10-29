import Foundation
@testable import Vylok

enum SubscriptionAccessSnapshotFixtures {
    nonisolated static func makeSnapshot(
        tier: SubscriptionTier = .premium,
        status: SubscriptionStatus = .active,
        paidAccessUntil: Date? = nil,
        capabilities: [SubscriptionCapability] = [.analytics, .customDateRange, .aiInput],
        aiRequestsLimit: Int = 10,
        aiRequestsRemaining: Int = 4,
        statusVersion: Int = 1,
        hasAiRequestsLimit: Bool? = true
    ) -> SubscriptionAccessSnapshot {
        SubscriptionAccessSnapshot(
            tier: tier,
            status: status,
            paidAccessUntil: paidAccessUntil,
            capabilities: capabilities,
            aiRequestsLimit: aiRequestsLimit,
            aiRequestsRemaining: aiRequestsRemaining,
            statusVersion: statusVersion,
            hasAiRequestsLimit: hasAiRequestsLimit
        )
    }

    /// Snapshot the backend returns for a raw tier name: paid tiers get every capability and 300 AI requests.
    nonisolated static func makeSnapshot(tierName: String) -> SubscriptionAccessSnapshot {
        let capabilities: [SubscriptionCapability] = switch tierName {
        case "PREMIUM", "PLUS", "ACTIVE":
            [.analytics, .customDateRange, .aiInput]
        default:
            []
        }

        return SubscriptionAccessSnapshot(
            tier: tierName == "REGULAR" ? .regular : .premium,
            status: .active,
            paidAccessUntil: nil,
            capabilities: capabilities,
            aiRequestsLimit: capabilities.isEmpty ? 0 : 300,
            aiRequestsRemaining: capabilities.isEmpty ? 0 : 300,
            statusVersion: 42
        )
    }
}
