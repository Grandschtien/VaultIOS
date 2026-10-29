import XCTest
import RevenueCat
@testable import Vylok

final class SubscriptionServiceTests: XCTestCase {
    private var revenueCatClient: SubscriptionRevenueCatClientProtocolMock!
    private var appLogService: AppLogServiceProtocolMock!
    private var firebaseTransactionLogger: FirebaseTransactionLoggingMock!

    override func setUp() {
        super.setUp()
        revenueCatClient = SubscriptionRevenueCatClientProtocolMock()
        appLogService = AppLogServiceProtocolMock()
        firebaseTransactionLogger = FirebaseTransactionLoggingMock()
    }

    override func tearDown() {
        firebaseTransactionLogger = nil
        appLogService = nil
        revenueCatClient = nil
        super.tearDown()
    }
}

// MARK: - loadPlans

extension SubscriptionServiceTests {
    func testLoadPlansWhenFreeTrialIsEligibleProducesTrialText() async throws {
        // Arrange
        let sut = SubscriptionService(
            revenueCatClient: revenueCatClient,
            appLogService: appLogService,
            firebaseTransactionLogger: firebaseTransactionLogger
        )
        revenueCatClient.fetchPackagesReturnValue = [
            SubscriptionRevenueCatPackage(
                productIdentifier: SubscriptionCatalog.premium.id,
                localizedPriceString: "$2.99",
                introductoryDiscount: .init(paymentMode: .freeTrial, subscriptionPeriod: .init(value: 7, unit: .day))
            )
        ]
        revenueCatClient.fetchCustomerInfoReturnValue = .init(activeEntitlementIDs: [])
        revenueCatClient.checkTrialOrIntroDiscountEligibilityPackagesReturnValue = [
            SubscriptionCatalog.premium.id: .eligible
        ]

        // Act
        let plans = try await sut.loadPlans()

        // Assert
        XCTAssertEqual(plans.first?.trialText, L10n.subscriptionTrialFreeFor(L10n.subscriptionTrialPeriodDays(7)))
    }

    func testLoadPlansWhenIntroductoryDiscountIsMissingHidesTrial() async throws {
        // Arrange
        let sut = SubscriptionService(
            revenueCatClient: revenueCatClient,
            appLogService: appLogService,
            firebaseTransactionLogger: firebaseTransactionLogger
        )
        revenueCatClient.fetchPackagesReturnValue = [
            SubscriptionRevenueCatPackage(
                productIdentifier: SubscriptionCatalog.premium.id,
                localizedPriceString: "$2.99"
            )
        ]
        revenueCatClient.fetchCustomerInfoReturnValue = .init(activeEntitlementIDs: [])
        revenueCatClient.checkTrialOrIntroDiscountEligibilityPackagesReturnValue = [
            SubscriptionCatalog.premium.id: .eligible
        ]

        // Act
        let plans = try await sut.loadPlans()

        // Assert
        XCTAssertNil(plans.first?.trialText)
    }

    func testLoadPlansWhenTrialIsIneligibleHidesTrial() async throws {
        // Arrange
        let sut = SubscriptionService(
            revenueCatClient: revenueCatClient,
            appLogService: appLogService,
            firebaseTransactionLogger: firebaseTransactionLogger
        )
        revenueCatClient.fetchPackagesReturnValue = [
            SubscriptionRevenueCatPackage(
                productIdentifier: SubscriptionCatalog.premium.id,
                localizedPriceString: "$2.99",
                introductoryDiscount: .init(paymentMode: .freeTrial, subscriptionPeriod: .init(value: 7, unit: .day))
            )
        ]
        revenueCatClient.fetchCustomerInfoReturnValue = .init(activeEntitlementIDs: [])
        revenueCatClient.checkTrialOrIntroDiscountEligibilityPackagesReturnValue = [
            SubscriptionCatalog.premium.id: .ineligible
        ]

        // Act
        let plans = try await sut.loadPlans()

        // Assert
        XCTAssertNil(plans.first?.trialText)
    }

    func testLoadPlansWhenEligibilityIsUnknownHidesTrial() async throws {
        // Arrange
        let sut = SubscriptionService(
            revenueCatClient: revenueCatClient,
            appLogService: appLogService,
            firebaseTransactionLogger: firebaseTransactionLogger
        )
        revenueCatClient.fetchPackagesReturnValue = [
            SubscriptionRevenueCatPackage(
                productIdentifier: SubscriptionCatalog.premium.id,
                localizedPriceString: "$2.99",
                introductoryDiscount: .init(paymentMode: .freeTrial, subscriptionPeriod: .init(value: 7, unit: .day))
            )
        ]
        revenueCatClient.fetchCustomerInfoReturnValue = .init(activeEntitlementIDs: [])
        revenueCatClient.checkTrialOrIntroDiscountEligibilityPackagesReturnValue = [
            SubscriptionCatalog.premium.id: .unknown
        ]

        // Act
        let plans = try await sut.loadPlans()

        // Assert
        XCTAssertNil(plans.first?.trialText)
    }

    func testLoadPlansWhenIntroOfferDoesNotExistHidesTrial() async throws {
        // Arrange
        let sut = SubscriptionService(
            revenueCatClient: revenueCatClient,
            appLogService: appLogService,
            firebaseTransactionLogger: firebaseTransactionLogger
        )
        revenueCatClient.fetchPackagesReturnValue = [
            SubscriptionRevenueCatPackage(
                productIdentifier: SubscriptionCatalog.premium.id,
                localizedPriceString: "$2.99",
                introductoryDiscount: .init(paymentMode: .freeTrial, subscriptionPeriod: .init(value: 7, unit: .day))
            )
        ]
        revenueCatClient.fetchCustomerInfoReturnValue = .init(activeEntitlementIDs: [])
        revenueCatClient.checkTrialOrIntroDiscountEligibilityPackagesReturnValue = [
            SubscriptionCatalog.premium.id: .noIntroOfferExists
        ]

        // Act
        let plans = try await sut.loadPlans()

        // Assert
        XCTAssertNil(plans.first?.trialText)
    }

    func testLoadPlansWhenDiscountIsNotFreeTrialHidesTrial() async throws {
        // Arrange
        let sut = SubscriptionService(
            revenueCatClient: revenueCatClient,
            appLogService: appLogService,
            firebaseTransactionLogger: firebaseTransactionLogger
        )
        revenueCatClient.fetchPackagesReturnValue = [
            SubscriptionRevenueCatPackage(
                productIdentifier: SubscriptionCatalog.premium.id,
                localizedPriceString: "$2.99",
                introductoryDiscount: .init(paymentMode: .payAsYouGo, subscriptionPeriod: .init(value: 1, unit: .month))
            )
        ]
        revenueCatClient.fetchCustomerInfoReturnValue = .init(activeEntitlementIDs: [])
        revenueCatClient.checkTrialOrIntroDiscountEligibilityPackagesReturnValue = [
            SubscriptionCatalog.premium.id: .eligible
        ]

        // Act
        let plans = try await sut.loadPlans()

        // Assert
        XCTAssertNil(plans.first?.trialText)
    }
}

// MARK: - purchase

extension SubscriptionServiceTests {
    func testPurchaseWhenRevenueCatReturnsTransactionTracksItAndUpdatesTier() async throws {
        // Arrange
        let sut = SubscriptionService(
            revenueCatClient: revenueCatClient,
            appLogService: appLogService,
            firebaseTransactionLogger: firebaseTransactionLogger
        )
        revenueCatClient.fetchPackagesReturnValue = [
            SubscriptionRevenueCatPackage(
                productIdentifier: SubscriptionCatalog.premium.id,
                localizedPriceString: "$2.99"
            )
        ]
        revenueCatClient.fetchCustomerInfoReturnValue = .init(activeEntitlementIDs: ["premium_access"])
        revenueCatClient.checkTrialOrIntroDiscountEligibilityPackagesReturnValue = [:]
        revenueCatClient.purchasePackageReturnValue = .init(
            transaction: StoreTransaction(
                productIdentifier: SubscriptionCatalog.premium.id,
                purchaseDate: Date(timeIntervalSince1970: 10),
                transactionIdentifier: "transaction-1"
            ),
            customerInfo: .init(activeEntitlementIDs: ["premium_access"])
        )
        _ = try await sut.loadPlans()

        // Act
        try await sut.purchase(planID: SubscriptionCatalog.premium.id)

        // Assert
        XCTAssertEqual(
            firebaseTransactionLogger.trackTransactionIfNeededReceivedInvocations.map { $0?.transactionIdentifier },
            ["transaction-1"]
        )
        XCTAssertEqual(sut.currentTier, .premium)
    }
}
