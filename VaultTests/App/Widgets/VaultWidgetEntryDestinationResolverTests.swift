import XCTest
@testable import Vault

final class VaultWidgetEntryDestinationResolverTests: XCTestCase {
    func testResolveDestinationReturnsAIEntryWhenCurrentSnapshotHasAiAccess() async {
        let subscriptionAccessService = SubscriptionAccessServiceSpy(
            currentSnapshot: .init(
                tier: .premium,
                status: .active,
                paidAccessUntil: nil,
                capabilities: [.aiInput],
                aiRequestsLimit: 10,
                aiRequestsRemaining: 4,
                statusVersion: 1,
                hasAiRequestsLimit: true
            )
        )
        let sut = VaultWidgetEntryDestinationResolver(
            subscriptionAccessService: subscriptionAccessService
        )

        let destination = await sut.resolveDestination()

        XCTAssertEqual(destination, .aiEntry)
        XCTAssertEqual(await subscriptionAccessService.currentSnapshotCallsCount(), 1)
        XCTAssertEqual(await subscriptionAccessService.refreshSnapshotCallsCount(), 0)
    }

    func testResolveDestinationReturnsManualEntryWhenCurrentSnapshotHasNoAiAccess() async {
        let subscriptionAccessService = SubscriptionAccessServiceSpy(
            currentSnapshot: .init(
                tier: .premium,
                status: .active,
                paidAccessUntil: nil,
                capabilities: [.aiInput],
                aiRequestsLimit: 10,
                aiRequestsRemaining: 0,
                statusVersion: 1,
                hasAiRequestsLimit: true
            ),
            refreshedSnapshot: nil
        )
        let sut = VaultWidgetEntryDestinationResolver(
            subscriptionAccessService: subscriptionAccessService
        )

        let destination = await sut.resolveDestination()

        XCTAssertEqual(destination, .manualEntry)
        XCTAssertEqual(await subscriptionAccessService.currentSnapshotCallsCount(), 1)
        XCTAssertEqual(await subscriptionAccessService.refreshSnapshotCallsCount(), 1)
    }

    func testResolveDestinationReturnsAIEntryWhenRefreshRestoresAiAccess() async {
        let subscriptionAccessService = SubscriptionAccessServiceSpy(
            currentSnapshot: .init(
                tier: .regular,
                status: .expired,
                paidAccessUntil: nil,
                capabilities: [],
                aiRequestsLimit: 0,
                aiRequestsRemaining: 0,
                statusVersion: 1
            ),
            refreshedSnapshot: .init(
                tier: .premium,
                status: .active,
                paidAccessUntil: nil,
                capabilities: [.aiInput],
                aiRequestsLimit: 10,
                aiRequestsRemaining: 3,
                statusVersion: 2,
                hasAiRequestsLimit: true
            )
        )
        let sut = VaultWidgetEntryDestinationResolver(
            subscriptionAccessService: subscriptionAccessService
        )

        let destination = await sut.resolveDestination()

        XCTAssertEqual(destination, .aiEntry)
        XCTAssertEqual(await subscriptionAccessService.currentSnapshotCallsCount(), 1)
        XCTAssertEqual(await subscriptionAccessService.refreshSnapshotCallsCount(), 1)
    }
}

private final class SubscriptionAccessServiceSpy: SubscriptionAccessServicing, @unchecked Sendable {
    private let currentSnapshotValue: SubscriptionAccessSnapshot?
    private let refreshedSnapshotValue: SubscriptionAccessSnapshot?
    private var currentSnapshotCalls: Int = .zero
    private var refreshSnapshotCalls: Int = .zero

    init(
        currentSnapshot: SubscriptionAccessSnapshot?,
        refreshedSnapshot: SubscriptionAccessSnapshot? = nil
    ) {
        currentSnapshotValue = currentSnapshot
        refreshedSnapshotValue = refreshedSnapshot
    }

    func currentTierState() async -> SubscriptionTierState {
        .resolved(.regular)
    }

    func refreshCurrentTierState() async -> SubscriptionTierState {
        .resolved(.regular)
    }

    func refreshCurrentTierSourceState() async -> SubscriptionTierRefreshState {
        .unavailable
    }

    func currentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot? {
        currentSnapshotCalls += 1
        return currentSnapshotValue
    }

    func refreshCurrentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot? {
        refreshSnapshotCalls += 1
        return refreshedSnapshotValue
    }

    func startMonitoring() {}

    func currentSnapshotCallsCount() async -> Int {
        currentSnapshotCalls
    }

    func refreshSnapshotCallsCount() async -> Int {
        refreshSnapshotCalls
    }
}
