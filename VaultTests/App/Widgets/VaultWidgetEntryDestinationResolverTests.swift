import XCTest
@testable import Vylok

final class VaultWidgetEntryDestinationResolverTests: XCTestCase {
    private var subscriptionAccessService: SubscriptionAccessServicingMock!
    private var sut: VylokWidgetEntryDestinationResolver!

    override func setUp() {
        super.setUp()
        subscriptionAccessService = SubscriptionAccessServicingMock()
        sut = VylokWidgetEntryDestinationResolver(subscriptionAccessService: subscriptionAccessService)
    }

    override func tearDown() {
        sut = nil
        subscriptionAccessService = nil
        super.tearDown()
    }
}

// MARK: - resolveDestination

extension VaultWidgetEntryDestinationResolverTests {
    func testResolveDestinationWhenCurrentSnapshotHasAiAccessReturnsAIEntryWithoutRefresh() async {
        // Arrange
        subscriptionAccessService.currentSubscriptionSnapshotReturnValue =
            SubscriptionAccessSnapshotFixtures.makeSnapshot(aiRequestsRemaining: 4)

        // Act
        let destination = await sut.resolveDestination()

        // Assert
        XCTAssertEqual(destination, .aiEntry)
        XCTAssertFalse(subscriptionAccessService.refreshCurrentSubscriptionSnapshotCalled)
    }

    func testResolveDestinationWhenNoAiAccessAndRefreshFailsReturnsManualEntry() async {
        // Arrange
        subscriptionAccessService.currentSubscriptionSnapshotReturnValue =
            SubscriptionAccessSnapshotFixtures.makeSnapshot(aiRequestsRemaining: 0)
        subscriptionAccessService.refreshCurrentSubscriptionSnapshotReturnValue = nil

        // Act
        let destination = await sut.resolveDestination()

        // Assert
        XCTAssertEqual(destination, .manualEntry)
        XCTAssertEqual(subscriptionAccessService.refreshCurrentSubscriptionSnapshotCallsCount, 1)
    }

    func testResolveDestinationWhenRefreshRestoresAiAccessReturnsAIEntry() async {
        // Arrange
        subscriptionAccessService.currentSubscriptionSnapshotReturnValue =
            SubscriptionAccessSnapshotFixtures.makeSnapshot(
                tier: .regular,
                status: .expired,
                capabilities: [],
                aiRequestsLimit: 0,
                aiRequestsRemaining: 0,
                hasAiRequestsLimit: nil
            )
        subscriptionAccessService.refreshCurrentSubscriptionSnapshotReturnValue =
            SubscriptionAccessSnapshotFixtures.makeSnapshot(aiRequestsRemaining: 3, statusVersion: 2)

        // Act
        let destination = await sut.resolveDestination()

        // Assert
        XCTAssertEqual(destination, .aiEntry)
    }
}
