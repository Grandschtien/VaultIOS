//
//  SubscriptionListener.swift
//  Vault
//
//  Created by Егор Шкарин on 21.04.2026.
//

import Foundation
import RevenueCat

protocol SubscriptionUpdatesListenerLogic: AnyObject {
    func start()
    func refresh() async
    func currentTier() async -> SubscriptionTier
}

final class SubscriptionUpdatesListener: NSObject, SubscriptionUpdatesListenerLogic {
    private let plusEntitlementID: String
    private let premiumEntitlementID: String
    private let store: SubscriptionTierStore

    init(
        plusEntitlementID: String = "plus_access",
        premiumEntitlementID: String = "premium_access",
        store: SubscriptionTierStore = SubscriptionTierStore()
    ) {
        self.plusEntitlementID = plusEntitlementID
        self.premiumEntitlementID = premiumEntitlementID
        self.store = store
        super.init()
    }

    func start() {
        Purchases.shared.delegate = self

        Task {
            await refresh()
        }
    }

    func refresh() async {
        do {
            let customerInfo = try await fetchCustomerInfo()
            await apply(customerInfo)
        } catch {
            assertionFailure("RevenueCat getCustomerInfo failed: \(error)")
        }
    }

    func currentTier() async -> SubscriptionTier {
        await store.value()
    }
}

private extension SubscriptionUpdatesListener {
    func fetchCustomerInfo() async throws -> CustomerInfo {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CustomerInfo, Error>) in
            Purchases.shared.getCustomerInfo { customerInfo, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let customerInfo else {
                    continuation.resume(throwing: SubscriptionListenerError.customerInfoMissing)
                    return
                }

                continuation.resume(returning: customerInfo)
            }
        }
    }

    func apply(_ customerInfo: CustomerInfo) async {
        let newTier = resolveTier(from: customerInfo)
        let didChange = await store.update(to: newTier)

        guard didChange else { return }

        await MainActor.run {
            NotificationCenter.default.post(
                name: .subscriptionTierDidChange,
                object: newTier
            )
        }
    }

    func resolveTier(from customerInfo: CustomerInfo) -> SubscriptionTier {
        let hasPremium = customerInfo.entitlements[premiumEntitlementID]?.isActive == true
        let hasPlus = customerInfo.entitlements[plusEntitlementID]?.isActive == true
        if hasPremium || hasPlus {
            return .premium
        }

        return .none
    }
}

extension SubscriptionUpdatesListener: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task {
            await apply(customerInfo)
        }
    }
}

private enum SubscriptionListenerError: Error {
    case customerInfoMissing
}

extension Notification.Name {
    static let subscriptionTierDidChange = Notification.Name("subscriptionTierDidChange")
}
