import XCTest
@testable import Vylok

final class VaultWidgetEntitlementStateResolverTests: XCTestCase {
    private let sut = VylokWidgetEntitlementStateResolver()

    func testResolveReturnsRegularForRegularTier() {
        let state = sut.resolve(
            from: SubscriptionAccessSnapshot(
                tier: .regular,
                status: .active,
                paidAccessUntil: nil,
                capabilities: [],
                aiRequestsLimit: 0,
                aiRequestsRemaining: 0,
                statusVersion: 1
            )
        )

        XCTAssertEqual(state, .regular)
    }

    func testResolveReturnsSubscribedForPremiumWithoutAiTokens() {
        let state = sut.resolve(
            from: SubscriptionAccessSnapshot(
                tier: .premium,
                status: .active,
                paidAccessUntil: nil,
                capabilities: [.aiInput],
                aiRequestsLimit: 10,
                aiRequestsRemaining: 0,
                statusVersion: 1,
                hasAiRequestsLimit: true
            )
        )

        XCTAssertEqual(state, .subscribed)
    }
}
