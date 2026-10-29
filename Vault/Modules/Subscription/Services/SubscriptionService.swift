// Created by Egor Shkarin 08.04.2026

import Foundation
import RevenueCat

// sourcery: AutoMockable
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

    var currentTier: SubscriptionTier = .regular
    var loadedPlans: [SubscriptionFetchData.SubscriptionStorePlan] = []

    private let plusEntitlementID: String
    private let premiumEntitlementID: String
    private let appLogService: AppLogServiceProtocol?
    private let firebaseTransactionLogger: FirebaseTransactionLogging?
    private let revenueCatClient: SubscriptionRevenueCatClientProtocol
    private var packagesByProductID: [String: SubscriptionRevenueCatPackage] = [:]

    init(
        plusEntitlementID: String = "plus_access",
        premiumEntitlementID: String = "premium_access",
        revenueCatClient: SubscriptionRevenueCatClientProtocol = SubscriptionRevenueCatClient(),
        appLogService: AppLogServiceProtocol? = nil,
        firebaseTransactionLogger: FirebaseTransactionLogging? = nil
    ) {
        self.plusEntitlementID = plusEntitlementID
        self.premiumEntitlementID = premiumEntitlementID
        self.revenueCatClient = revenueCatClient
        self.appLogService = appLogService
        self.firebaseTransactionLogger = firebaseTransactionLogger
    }

    @discardableResult
    func loadPlans() async throws -> [SubscriptionFetchData.SubscriptionStorePlan] {
        do {
            async let packages = revenueCatClient.fetchPackages()
            async let customerInfo = revenueCatClient.fetchCustomerInfo()

            let (resolvedPackages, resolvedCustomerInfo) = try await (packages, customerInfo)
            guard !resolvedPackages.isEmpty else {
                throw SubscriptionServiceError.emptyOfferings
            }

            let filteredPackages = resolvedPackages.filter { package in
                SubscriptionCatalog.orderedPlans.contains {
                    $0.id == package.productIdentifier
                }
            }
            let eligibilityByProductID = await revenueCatClient
                .checkTrialOrIntroDiscountEligibility(packages: filteredPackages)

            packagesByProductID = Dictionary(
                uniqueKeysWithValues: filteredPackages.map {
                    ($0.productIdentifier, $0)
                }
            )

            loadedPlans = SubscriptionCatalog.orderedPlans.compactMap { plan in
                guard let package = packagesByProductID[plan.id] else { return nil }

                return SubscriptionFetchData.SubscriptionStorePlan(
                    id: plan.id,
                    title: plan.title,
                    price: package.localizedPriceString,
                    trialText: SubscriptionTrialResolver.resolveTrialText(
                        from: package.introductoryDiscount,
                        eligibility: eligibilityByProductID[plan.id] ?? .unknown
                    )
                )
            }

            currentTier = resolveTier(from: resolvedCustomerInfo)
            appLogService?.log(
                category: .subscription,
                name: "load_plans_result",
                source: "SubscriptionService",
                payload: [
                    "result": "success",
                    "plan_count": loadedPlans.count,
                    "current_tier": currentTier.rawValue
                ]
            )
            return loadedPlans
        } catch {
            appLogService?.log(
                category: .subscription,
                name: "load_plans_result",
                source: "SubscriptionService",
                payload: [
                    "result": "failure",
                    "error_description": error.localizedDescription
                ]
            )
            throw error
        }
    }

    func purchase(planID: String) async throws {
        if packagesByProductID[planID] == nil {
            _ = try await loadPlans()
        }

        guard let package = packagesByProductID[planID] else {
            throw SubscriptionServiceError.packageNotFound(planID)
        }

        let purchaseResult = try await revenueCatClient.purchase(package: package)
        await firebaseTransactionLogger?.trackTransactionIfNeeded(purchaseResult.transaction)
        currentTier = resolveTier(from: purchaseResult.customerInfo)
    }

    func restore() async throws {
        let customerInfo = try await revenueCatClient.restorePurchases()
        currentTier = resolveTier(from: customerInfo)
    }

    func refreshCurrentTier() async throws {
        let customerInfo = try await revenueCatClient.fetchCustomerInfo()
        currentTier = resolveTier(from: customerInfo)
    }

    func manualSync() async throws {
        let customerInfo = try await revenueCatClient.syncPurchases()
        currentTier = resolveTier(from: customerInfo)
    }
}

private extension SubscriptionService {
    func resolveTier(from customerInfo: SubscriptionRevenueCatCustomerInfo) -> SubscriptionTier {
        let hasPremium = customerInfo.hasActiveEntitlement(premiumEntitlementID)
        let hasPlus = customerInfo.hasActiveEntitlement(plusEntitlementID)
        if hasPremium || hasPlus {
            return .premium
        }

        return .regular
    }
}

// sourcery: AutoMockable
protocol SubscriptionRevenueCatClientProtocol: AnyObject {
    func fetchPackages() async throws -> [SubscriptionRevenueCatPackage]
    func fetchCustomerInfo() async throws -> SubscriptionRevenueCatCustomerInfo
    func checkTrialOrIntroDiscountEligibility(
        packages: [SubscriptionRevenueCatPackage]
    ) async -> [String: IntroEligibilityStatus]
    func purchase(package: SubscriptionRevenueCatPackage) async throws -> SubscriptionRevenueCatPurchaseResult
    func restorePurchases() async throws -> SubscriptionRevenueCatCustomerInfo
    func syncPurchases() async throws -> SubscriptionRevenueCatCustomerInfo
}

struct SubscriptionRevenueCatPurchaseResult {
    let transaction: StoreTransaction?
    let customerInfo: SubscriptionRevenueCatCustomerInfo
}

struct SubscriptionRevenueCatPackage {
    let productIdentifier: String
    let localizedPriceString: String
    let introductoryDiscount: SubscriptionRevenueCatDiscount?
    fileprivate let sourcePackage: Package?

    init(
        productIdentifier: String,
        localizedPriceString: String,
        introductoryDiscount: SubscriptionRevenueCatDiscount? = nil,
        sourcePackage: Package? = nil
    ) {
        self.productIdentifier = productIdentifier
        self.localizedPriceString = localizedPriceString
        self.introductoryDiscount = introductoryDiscount
        self.sourcePackage = sourcePackage
    }

    init(package: Package) {
        self.init(
            productIdentifier: package.storeProduct.productIdentifier,
            localizedPriceString: package.storeProduct.localizedPriceString,
            introductoryDiscount: package.storeProduct.introductoryDiscount.map(SubscriptionRevenueCatDiscount.init),
            sourcePackage: package
        )
    }
}

struct SubscriptionRevenueCatDiscount {
    let paymentMode: StoreProductDiscount.PaymentMode
    let subscriptionPeriod: SubscriptionPeriod

    init(
        paymentMode: StoreProductDiscount.PaymentMode,
        subscriptionPeriod: SubscriptionPeriod
    ) {
        self.paymentMode = paymentMode
        self.subscriptionPeriod = subscriptionPeriod
    }

    init(discount: StoreProductDiscount) {
        self.init(
            paymentMode: discount.paymentMode,
            subscriptionPeriod: discount.subscriptionPeriod
        )
    }
}

struct SubscriptionRevenueCatCustomerInfo {
    let activeEntitlementIDs: Set<String>

    func hasActiveEntitlement(_ id: String) -> Bool {
        activeEntitlementIDs.contains(id)
    }
}

final class SubscriptionRevenueCatClient: SubscriptionRevenueCatClientProtocol {
    func fetchPackages() async throws -> [SubscriptionRevenueCatPackage] {
        try await withCheckedThrowingContinuation { (
            continuation: CheckedContinuation<[SubscriptionRevenueCatPackage], Error>
        ) in
            Purchases.shared.getOfferings { offerings, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let offerings else {
                    continuation.resume(throwing: SubscriptionServiceError.emptyOfferings)
                    return
                }

                let packages = offerings.current?.availablePackages.map(SubscriptionRevenueCatPackage.init) ?? []
                continuation.resume(returning: packages)
            }
        }
    }

    func fetchCustomerInfo() async throws -> SubscriptionRevenueCatCustomerInfo {
        try await withCheckedThrowingContinuation { (
            continuation: CheckedContinuation<SubscriptionRevenueCatCustomerInfo, Error>
        ) in
            Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
                guard let self else { return }
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let customerInfo else {
                    continuation.resume(throwing: SubscriptionServiceError.failedToResolveTier)
                    return
                }

                continuation.resume(returning: makeCustomerInfo(from: customerInfo))
            }
        }
    }

    func checkTrialOrIntroDiscountEligibility(
        packages: [SubscriptionRevenueCatPackage]
    ) async -> [String: IntroEligibilityStatus] {
        let sourcePackages = packages.compactMap(\.sourcePackage)
        guard sourcePackages.count == packages.count else {
            return Dictionary(
                uniqueKeysWithValues: packages.map { ($0.productIdentifier, .unknown) }
            )
        }

        let eligibilityByPackage = await Purchases.shared
            .checkTrialOrIntroDiscountEligibility(packages: sourcePackages)

        return Dictionary(
            uniqueKeysWithValues: packages.map { package in
                let sourcePackage = package.sourcePackage
                let status = sourcePackage.flatMap { eligibilityByPackage[$0]?.status } ?? .unknown
                return (package.productIdentifier, status)
            }
        )
    }

    func purchase(package: SubscriptionRevenueCatPackage) async throws -> SubscriptionRevenueCatPurchaseResult {
        guard let sourcePackage = package.sourcePackage else {
            throw SubscriptionServiceError.packageNotFound(package.productIdentifier)
        }

        let purchaseResult = try await Purchases.shared.purchase(package: sourcePackage)
        if purchaseResult.userCancelled {
            throw SubscriptionServiceError.purchaseCancelled
        }

        return SubscriptionRevenueCatPurchaseResult(
            transaction: purchaseResult.transaction,
            customerInfo: makeCustomerInfo(from: purchaseResult.customerInfo)
        )
    }

    func restorePurchases() async throws -> SubscriptionRevenueCatCustomerInfo {
        try await withCheckedThrowingContinuation { (
            continuation: CheckedContinuation<SubscriptionRevenueCatCustomerInfo, Error>
        ) in
            Purchases.shared.restorePurchases { [weak self] customerInfo, error in
                guard let self else { return }
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let customerInfo else {
                    continuation.resume(throwing: SubscriptionServiceError.failedToResolveTier)
                    return
                }

                continuation.resume(returning: makeCustomerInfo(from: customerInfo))
            }
        }
    }

    func syncPurchases() async throws -> SubscriptionRevenueCatCustomerInfo {
        try await withCheckedThrowingContinuation { (
            continuation: CheckedContinuation<SubscriptionRevenueCatCustomerInfo, Error>
        ) in
            Purchases.shared.syncPurchases { [weak self] customerInfo, error in
                guard let self else { return }
    
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let customerInfo else {
                    continuation.resume(throwing: SubscriptionServiceError.failedToResolveTier)
                    return
                }

                continuation.resume(returning: makeCustomerInfo(from: customerInfo))
            }
        }
    }
}

private extension SubscriptionRevenueCatClient {
    func makeCustomerInfo(from customerInfo: CustomerInfo) -> SubscriptionRevenueCatCustomerInfo {
        return SubscriptionRevenueCatCustomerInfo(
            activeEntitlementIDs: Set(customerInfo.entitlements.active.keys)
        )
    }
}
