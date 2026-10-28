import XCTest
import RevenueCat
@testable import Vylok

final class SubscriptionServiceTests: XCTestCase {
    func testLoadPlansEligibleFreeTrialProducesTrialText() async throws {
        let trialText = try await loadTrialText(
            discount: .init(
                paymentMode: .freeTrial,
                subscriptionPeriod: .init(value: 7, unit: .day)
            ),
            eligibility: .eligible
        )

        XCTAssertEqual(
            trialText,
            L10n.subscriptionTrialFreeFor(
                L10n.subscriptionTrialPeriodDays(7)
            )
        )
    }

    func testLoadPlansWithoutIntroductoryDiscountKeepsTrialHidden() async throws {
        let trialText = try await loadTrialText(
            discount: nil,
            eligibility: .eligible
        )

        XCTAssertNil(trialText)
    }

    func testLoadPlansIneligibleTrialKeepsTrialHidden() async throws {
        let trialText = try await loadTrialText(
            discount: .init(
                paymentMode: .freeTrial,
                subscriptionPeriod: .init(value: 7, unit: .day)
            ),
            eligibility: .ineligible
        )

        XCTAssertNil(trialText)
    }

    func testLoadPlansUnknownEligibilityKeepsTrialHidden() async throws {
        let trialText = try await loadTrialText(
            discount: .init(
                paymentMode: .freeTrial,
                subscriptionPeriod: .init(value: 7, unit: .day)
            ),
            eligibility: .unknown
        )

        XCTAssertNil(trialText)
    }

    func testLoadPlansWithoutIntroOfferEligibilityKeepsTrialHidden() async throws {
        let trialText = try await loadTrialText(
            discount: .init(
                paymentMode: .freeTrial,
                subscriptionPeriod: .init(value: 7, unit: .day)
            ),
            eligibility: .noIntroOfferExists
        )

        XCTAssertNil(trialText)
    }

    func testLoadPlansNonFreeTrialKeepsTrialHidden() async throws {
        let trialText = try await loadTrialText(
            discount: .init(
                paymentMode: .payAsYouGo,
                subscriptionPeriod: .init(value: 1, unit: .month)
            ),
            eligibility: .eligible
        )

        XCTAssertNil(trialText)
    }

    func testPurchaseTracksFirebaseTransactionWhenRevenueCatReturnsTransaction() async throws {
        let firebaseTransactionLogger = FirebaseTransactionLoggingSpy()
        let transaction = StoreTransaction(
            productIdentifier: SubscriptionCatalog.premium.id,
            purchaseDate: Date(timeIntervalSince1970: 10),
            transactionIdentifier: "transaction-1"
        )
        let client = SubscriptionRevenueCatClientStub(
            packages: [
                .init(
                    productIdentifier: SubscriptionCatalog.premium.id,
                    localizedPriceString: "$2.99"
                )
            ],
            customerInfo: .init(activeEntitlementIDs: ["premium_access"]),
            purchaseResult: .init(
                transaction: transaction,
                customerInfo: .init(activeEntitlementIDs: ["premium_access"])
            )
        )
        let sut = SubscriptionService(
            revenueCatClient: client,
            appLogService: AppLogServiceSpy(),
            firebaseTransactionLogger: firebaseTransactionLogger
        )

        _ = try await sut.loadPlans()
        try await sut.purchase(planID: SubscriptionCatalog.premium.id)

        let trackedTransaction = await firebaseTransactionLogger.trackedTransaction()
        XCTAssertEqual(trackedTransaction?.productIdentifier, SubscriptionCatalog.premium.id)
        XCTAssertEqual(sut.currentTier, .premium)
    }
}

private extension SubscriptionServiceTests {
    func loadTrialText(
        discount: SubscriptionRevenueCatDiscount?,
        eligibility: IntroEligibilityStatus
    ) async throws -> String? {
        let client = SubscriptionRevenueCatClientStub(
            packages: [
                .init(
                    productIdentifier: SubscriptionCatalog.premium.id,
                    localizedPriceString: "$2.99",
                    introductoryDiscount: discount
                )
            ],
            customerInfo: .init(activeEntitlementIDs: [])
        )
        client.eligibilityByProductID = [SubscriptionCatalog.premium.id: eligibility]
        let sut = SubscriptionService(
            revenueCatClient: client,
            appLogService: AppLogServiceSpy()
        )

        return try await sut.loadPlans().first?.trialText
    }
}

private final class SubscriptionRevenueCatClientStub: SubscriptionRevenueCatClientProtocol, @unchecked Sendable {
    private let packages: [SubscriptionRevenueCatPackage]
    private let customerInfo: SubscriptionRevenueCatCustomerInfo
    private let purchaseResult: SubscriptionRevenueCatPurchaseResult

    var eligibilityByProductID: [String: IntroEligibilityStatus] = [:]

    init(
        packages: [SubscriptionRevenueCatPackage],
        customerInfo: SubscriptionRevenueCatCustomerInfo,
        purchaseResult: SubscriptionRevenueCatPurchaseResult? = nil
    ) {
        self.packages = packages
        self.customerInfo = customerInfo
        self.purchaseResult = purchaseResult ?? .init(
            transaction: nil,
            customerInfo: customerInfo
        )
    }

    func fetchPackages() async throws -> [SubscriptionRevenueCatPackage] {
        packages
    }

    func fetchCustomerInfo() async throws -> SubscriptionRevenueCatCustomerInfo {
        customerInfo
    }

    func checkTrialOrIntroDiscountEligibility(
        packages: [SubscriptionRevenueCatPackage]
    ) async -> [String: IntroEligibilityStatus] {
        Dictionary(
            uniqueKeysWithValues: packages.map { package in
                (package.productIdentifier, eligibilityByProductID[package.productIdentifier] ?? .unknown)
            }
        )
    }

    func purchase(package: SubscriptionRevenueCatPackage) async throws -> SubscriptionRevenueCatPurchaseResult {
        purchaseResult
    }

    func restorePurchases() async throws -> SubscriptionRevenueCatCustomerInfo {
        customerInfo
    }

    func syncPurchases() async throws -> SubscriptionRevenueCatCustomerInfo {
        customerInfo
    }
}

private actor FirebaseTransactionLoggingSpy: FirebaseTransactionLogging {
    private var storedTransaction: StoreTransaction?

    func trackTransactionIfNeeded(_ transaction: StoreTransaction?) async {
        storedTransaction = transaction
    }

    func trackedTransaction() -> StoreTransaction? {
        storedTransaction
    }
}
