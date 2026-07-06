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

    var eligibilityByProductID: [String: IntroEligibilityStatus] = [:]

    init(
        packages: [SubscriptionRevenueCatPackage],
        customerInfo: SubscriptionRevenueCatCustomerInfo
    ) {
        self.packages = packages
        self.customerInfo = customerInfo
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

    func purchase(package: SubscriptionRevenueCatPackage) async throws -> SubscriptionRevenueCatCustomerInfo {
        customerInfo
    }

    func restorePurchases() async throws -> SubscriptionRevenueCatCustomerInfo {
        customerInfo
    }

    func syncPurchases() async throws -> SubscriptionRevenueCatCustomerInfo {
        customerInfo
    }
}
