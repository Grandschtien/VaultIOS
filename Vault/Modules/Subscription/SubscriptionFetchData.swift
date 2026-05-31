// Created by Egor Shkarin 08.04.2026

import Foundation

struct SubscriptionFetchData: Sendable {
    let title: String
    let loadingState: LoadingStatus
    let currentTier: String
    let plans: [SubscriptionStorePlan]
    let purchasingPlanID: String?
    let isPurchaseSyncing: Bool
    let isRestoringPurchase: Bool
    
    struct SubscriptionStorePlan: Equatable, Sendable {
        let id: String
        let title: String
        let price: String
    }

    init(
        title: String = L10n.subscriptionTitle,
        loadingState: LoadingStatus = .idle,
        currentTier: String = "",
        plans: [SubscriptionStorePlan] = [],
        purchasingPlanID: String? = nil,
        isPurchaseSyncing: Bool = false,
        isRestoringPurchase: Bool = false
    ) {
        self.title = title
        self.loadingState = loadingState
        self.currentTier = currentTier
        self.plans = plans
        self.purchasingPlanID = purchasingPlanID
        self.isPurchaseSyncing = isPurchaseSyncing
        self.isRestoringPurchase = isRestoringPurchase
    }
}
