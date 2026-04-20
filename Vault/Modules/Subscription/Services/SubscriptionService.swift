// Created by Egor Shkarin 08.04.2026

import Foundation
import RevenueCat

protocol SubscriptionServiceLogic: AnyObject {
    var currentTier: SubscriptionTier { get }
    var loadedPlans: [SubscriptionFetchData.SubscriptionStorePlan] { get }

    @discardableResult
    func loadPlans() async throws -> [SubscriptionFetchData.SubscriptionStorePlan]

    func purchase(planID: String) async throws
    func restore() async throws
    func refreshCurrentTier() async throws
    func manualSync() async throws
}

final class SubscriptionService: SubscriptionServiceLogic {

    var currentTier: SubscriptionTier = .none
    var loadedPlans: [SubscriptionFetchData.SubscriptionStorePlan] = []

    private let plusEntitlementID: String
    private let premiumEntitlementID: String
    private var packagesByProductID: [String: Package] = [:]

    init(
        plusEntitlementID: String = "plus_access",
        premiumEntitlementID: String = "premium_access"
    ) {
        self.plusEntitlementID = plusEntitlementID
        self.premiumEntitlementID = premiumEntitlementID
    }

    @discardableResult
    func loadPlans() async throws -> [SubscriptionFetchData.SubscriptionStorePlan] {
        async let offerings = fetchOfferings()
        async let customerInfo = fetchCustomerInfo()

        let (resolvedOfferings, resolvedCustomerInfo) = try await (offerings, customerInfo)

        guard let packages = resolvedOfferings.current?.availablePackages, !packages.isEmpty else {
            throw SubscriptionServiceError.emptyOfferings
        }

        let filteredPackages = packages.filter { package in
            SubscriptionCatalog.orderedPlans.contains {
                $0.id == package.storeProduct.productIdentifier
            }
        }

        packagesByProductID = Dictionary(
            uniqueKeysWithValues: filteredPackages.map {
                ($0.storeProduct.productIdentifier, $0)
            }
        )

        loadedPlans = SubscriptionCatalog.orderedPlans.compactMap { plan in
            guard let package = packagesByProductID[plan.id] else { return nil }

            return SubscriptionFetchData.SubscriptionStorePlan(
                id: plan.id,
                title: plan.title,
                price: package.storeProduct.localizedPriceString
            )
        }

        currentTier = resolveTier(from: resolvedCustomerInfo)
        return loadedPlans
    }

    func purchase(planID: String) async throws {
        if packagesByProductID[planID] == nil {
            _ = try await loadPlans()
        }

        guard let package = packagesByProductID[planID] else {
            throw SubscriptionServiceError.packageNotFound(planID)
        }

        let customerInfo = try await purchase(package: package)
        currentTier = resolveTier(from: customerInfo)
    }

    func restore() async throws {
        let customerInfo = try await restorePurchases()
        currentTier = resolveTier(from: customerInfo)
    }

    func refreshCurrentTier() async throws {
        let customerInfo = try await fetchCustomerInfo()
        currentTier = resolveTier(from: customerInfo)
    }

    func manualSync() async throws {
        let customerInfo = try await syncPurchases()
        currentTier = resolveTier(from: customerInfo)
    }
}

private extension SubscriptionService {
    func resolveTier(from customerInfo: CustomerInfo) -> SubscriptionTier {
        let hasPremium = customerInfo.entitlements[premiumEntitlementID]?.isActive == true
        if hasPremium {
            return .premium
        }

        let hasPlus = customerInfo.entitlements[plusEntitlementID]?.isActive == true
        if hasPlus {
            return .plus
        }

        return .none
    }
}

private extension SubscriptionService {
    func fetchOfferings() async throws -> Offerings {
        try await withCheckedThrowingContinuation { continuation in
            Purchases.shared.getOfferings { offerings, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let offerings else {
                    continuation.resume(throwing: SubscriptionServiceError.emptyOfferings)
                    return
                }

                continuation.resume(returning: offerings)
            }
        }
    }

    func fetchCustomerInfo() async throws -> CustomerInfo {
        try await withCheckedThrowingContinuation { continuation in
            Purchases.shared.getCustomerInfo { customerInfo, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let customerInfo else {
                    continuation.resume(throwing: SubscriptionServiceError.failedToResolveTier)
                    return
                }

                continuation.resume(returning: customerInfo)
            }
        }
    }

    func purchase(package: Package) async throws -> CustomerInfo {
        try await withCheckedThrowingContinuation { continuation in
            Purchases.shared.purchase(package: package) { _, customerInfo, error, userCancelled in
                if userCancelled {
                    continuation.resume(throwing: SubscriptionServiceError.purchaseCancelled)
                    return
                }

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let customerInfo else {
                    continuation.resume(throwing: SubscriptionServiceError.failedToResolveTier)
                    return
                }

                continuation.resume(returning: customerInfo)
            }
        }
    }

    func restorePurchases() async throws -> CustomerInfo {
        try await withCheckedThrowingContinuation { continuation in
            Purchases.shared.restorePurchases { customerInfo, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let customerInfo else {
                    continuation.resume(throwing: SubscriptionServiceError.failedToResolveTier)
                    return
                }

                continuation.resume(returning: customerInfo)
            }
        }
    }

    func syncPurchases() async throws -> CustomerInfo {
        try await withCheckedThrowingContinuation { continuation in
            Purchases.shared.syncPurchases { customerInfo, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let customerInfo else {
                    continuation.resume(throwing: SubscriptionServiceError.failedToResolveTier)
                    return
                }

                continuation.resume(returning: customerInfo)
            }
        }
    }
}
