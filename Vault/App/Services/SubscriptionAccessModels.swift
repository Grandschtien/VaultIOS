// Created by Egor Shkarin 31.05.2026

import Foundation

enum SubscriptionCapability: String, Sendable, Codable {
    case analytics
    case customDateRange = "custom_date_range"
    case aiInput = "ai_input"
}

enum SubscriptionTier: String, Sendable, Codable {
    case regular = "REGULAR"
    case premium = "PREMIUM"
}

enum SubscriptionStatus: String, Sendable, Codable {
    case active
    case cancelPending = "cancel_pending"
    case expired
    case revoked
}

struct SubscriptionAccessSnapshot: Codable, Equatable, Sendable {
    let tier: SubscriptionTier
    let status: SubscriptionStatus
    let paidAccessUntil: Date?
    let capabilities: [SubscriptionCapability]
    let aiRequestsLimit: Int
    let aiRequestsRemaining: Int
    let statusVersion: Int
    private let aiRequestsLimitProvided: Bool?

    var hasAnalyticsAccess: Bool {
        hasCapability(.analytics)
    }

    var hasCustomDateRangeAccess: Bool {
        hasCapability(.customDateRange)
    }

    var hasAiInputAccess: Bool {
        hasCapability(.aiInput) && aiRequestsRemaining > 0
    }

    var hasAiRequestsLimit: Bool {
        aiRequestsLimitProvided
            ?? (
                aiRequestsLimit > .zero
                || aiRequestsRemaining > .zero
            )
    }

    var aiRequestsUsed: Int {
        min(
            max(aiRequestsLimit - aiRequestsRemaining, .zero),
            aiRequestsLimit
        )
    }

    var hasActiveSubscription: Bool {
        status == .active
    }

    init(
        tier: SubscriptionTier,
        status: SubscriptionStatus,
        paidAccessUntil: Date?,
        capabilities: [SubscriptionCapability],
        aiRequestsLimit: Int,
        aiRequestsRemaining: Int,
        statusVersion: Int,
        hasAiRequestsLimit: Bool? = nil
    ) {
        self.tier = tier
        self.status = status
        self.paidAccessUntil = paidAccessUntil
        self.capabilities = capabilities
        self.aiRequestsLimit = aiRequestsLimit
        self.aiRequestsRemaining = aiRequestsRemaining
        self.statusVersion = statusVersion
        aiRequestsLimitProvided = hasAiRequestsLimit
    }

    init(response: SubscriptionAccessResponseDTO) {
        self.init(
            tier: response.tier,
            status: response.status,
            paidAccessUntil: response.paidAccessUntil,
            capabilities: response.capabilities,
            aiRequestsLimit: response.usageLimits?.aiRequests.limit ?? 0,
            aiRequestsRemaining: response.usageLimits?.aiRequests.remaining ?? 0,
            statusVersion: response.statusVersion,
            hasAiRequestsLimit: response.usageLimits != nil
        )
    }

    func hasCapability(_ capability: SubscriptionCapability) -> Bool {
        capabilities.contains(capability)
    }
}

struct SubscriptionAccessResponseDTO: Codable, Equatable, Sendable {
    let tier: SubscriptionTier
    let status: SubscriptionStatus
    let paidAccessUntil: Date?
    let capabilities: [SubscriptionCapability]
    let usageLimits: UsageLimitsDTO?
    let statusVersion: Int
}

extension SubscriptionAccessResponseDTO {
    struct UsageLimitsDTO: Codable, Equatable, Sendable {
        let aiRequests: AIRequestsDTO
    }

    struct AIRequestsDTO: Codable, Equatable, Sendable {
        let limit: Int
        let remaining: Int
    }
}
