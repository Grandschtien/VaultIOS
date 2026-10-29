import XCTest
@testable import Vylok

final class SubscriptionAccessServiceTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_783_166_400)

    private var subscriptionService: SubscriptionAccessContractServicingMock!
    private var userProfileStorageService: UserProfileStorageServiceProtocolMock!
    private var notificationCenter: NotificationCenter!
    private var sut: SubscriptionAccessService!

    override func setUp() {
        super.setUp()
        subscriptionService = SubscriptionAccessContractServicingMock()
        userProfileStorageService = UserProfileStorageServiceProtocolMock()
        notificationCenter = NotificationCenter()
        let now = now
        sut = SubscriptionAccessService(
            subscriptionService: subscriptionService,
            userProfileStorageService: userProfileStorageService,
            notificationCenter: notificationCenter,
            currentDate: { now }
        )
    }

    override func tearDown() {
        sut = nil
        notificationCenter = nil
        userProfileStorageService = nil
        subscriptionService = nil
        super.tearDown()
    }
}

// MARK: - currentTierState

extension SubscriptionAccessServiceTests {
    func testCurrentTierStateWhenUserIsSignedOutReturnsRegular() async {
        // Arrange
        userProfileStorageService.loadProfileReturnValue = nil

        // Act
        let result = await sut.currentTierState()

        // Assert
        XCTAssertEqual(result, .resolved(.regular))
        XCTAssertFalse(subscriptionService.getSubscriptionCalled)
    }

    func testCurrentTierStateFetchesOnceCachesAndPersistsSnapshot() async {
        // Arrange
        let snapshot = SubscriptionAccessSnapshotFixtures.makeSnapshot(tier: .premium)
        userProfileStorageService.loadProfileReturnValue = makeProfile(userID: "user-1")
        subscriptionService.getSubscriptionReturnValue = snapshot
        _ = await sut.currentTierState()

        // Act
        let result = await sut.currentTierState()

        // Assert
        XCTAssertEqual(result, .resolved(.premium))
        XCTAssertEqual(subscriptionService.getSubscriptionCallsCount, 1)
        XCTAssertEqual(
            userProfileStorageService.saveProfileReceivedInvocations,
            [makeProfile(userID: "user-1", cachedSubscription: snapshot)]
        )
    }

    func testCurrentTierStateWhenProfileHasPersistedSnapshotSkipsNetwork() async {
        // Arrange
        userProfileStorageService.loadProfileReturnValue = makeProfile(
            userID: "user-1",
            cachedSubscription: SubscriptionAccessSnapshotFixtures.makeSnapshot(tier: .premium)
        )

        // Act
        let result = await sut.currentTierState()

        // Assert
        XCTAssertEqual(result, .resolved(.premium))
        XCTAssertFalse(subscriptionService.getSubscriptionCalled)
    }

    func testCurrentTierStateWhenPersistedSnapshotExpiredRefreshesIt() async {
        // Arrange
        userProfileStorageService.loadProfileReturnValue = makeProfile(
            userID: "user-1",
            cachedSubscription: SubscriptionAccessSnapshotFixtures.makeSnapshot(
                tier: .premium,
                paidAccessUntil: Date(timeIntervalSince1970: 1_783_000_000),
                statusVersion: 1
            )
        )
        subscriptionService.refreshSubscriptionReturnValue = SubscriptionAccessSnapshotFixtures.makeSnapshot(
            tier: .regular,
            status: .expired,
            statusVersion: 2
        )

        // Act
        let result = await sut.currentTierState()

        // Assert
        XCTAssertEqual(result, .resolved(.regular))
        XCTAssertEqual(subscriptionService.refreshSubscriptionCallsCount, 1)
    }

    func testCurrentTierStateWhenFetchFailsWithoutCacheReturnsUnavailable() async {
        // Arrange
        userProfileStorageService.loadProfileReturnValue = makeProfile(userID: "user-1")
        subscriptionService.getSubscriptionThrowableError = TestError.any

        // Act
        let result = await sut.currentTierState()

        // Assert
        XCTAssertEqual(result, .unavailable)
    }

    func testCurrentTierStateWhenUserChangesFetchesSnapshotForNewUser() async {
        // Arrange
        userProfileStorageService.loadProfileReturnValue = makeProfile(userID: "user-1")
        subscriptionService.getSubscriptionReturnValue = SubscriptionAccessSnapshotFixtures.makeSnapshot(tier: .premium)
        _ = await sut.currentTierState()
        userProfileStorageService.loadProfileReturnValue = makeProfile(userID: "user-2")
        subscriptionService.getSubscriptionReturnValue = SubscriptionAccessSnapshotFixtures.makeSnapshot(tier: .regular)

        // Act
        let result = await sut.currentTierState()

        // Assert
        XCTAssertEqual(result, .resolved(.regular))
        XCTAssertEqual(subscriptionService.getSubscriptionCallsCount, 2)
    }

    func testCurrentTierStateAfterLogoutNotificationFetchesAgain() async throws {
        // Arrange
        userProfileStorageService.loadProfileReturnValue = makeProfile(userID: "user-1")
        subscriptionService.getSubscriptionReturnValue = SubscriptionAccessSnapshotFixtures.makeSnapshot(tier: .premium)
        _ = await sut.currentTierState()
        notificationCenter.post(name: .authSessionDidLogout, object: nil)
        try await Task.sleep(for: .milliseconds(200))

        // Act
        _ = await sut.currentTierState()

        // Assert
        XCTAssertEqual(subscriptionService.getSubscriptionCallsCount, 2)
    }
}

// MARK: - refreshCurrentTierSourceState

extension SubscriptionAccessServiceTests {
    func testRefreshCurrentTierSourceStateWhenResponseIsNewerReturnsNetworkTier() async {
        // Arrange
        userProfileStorageService.loadProfileReturnValue = makeProfile(
            userID: "user-1",
            cachedSubscription: SubscriptionAccessSnapshotFixtures.makeSnapshot(tier: .regular, statusVersion: 1)
        )
        subscriptionService.refreshSubscriptionReturnValue =
            SubscriptionAccessSnapshotFixtures.makeSnapshot(tier: .premium, statusVersion: 2)

        // Act
        let result = await sut.refreshCurrentTierSourceState()

        // Assert
        XCTAssertEqual(result, .network(.premium))
    }

    func testRefreshCurrentTierSourceStateWhenResponseIsOlderKeepsCachedTier() async {
        // Arrange
        userProfileStorageService.loadProfileReturnValue = makeProfile(
            userID: "user-1",
            cachedSubscription: SubscriptionAccessSnapshotFixtures.makeSnapshot(tier: .premium, statusVersion: 5)
        )
        subscriptionService.refreshSubscriptionReturnValue =
            SubscriptionAccessSnapshotFixtures.makeSnapshot(tier: .regular, statusVersion: 4)

        // Act
        let result = await sut.refreshCurrentTierSourceState()

        // Assert
        XCTAssertEqual(result, .cache(.premium))
        XCTAssertFalse(userProfileStorageService.saveProfileCalled)
    }

    func testRefreshCurrentTierSourceStateWhenRefreshFailsWithCacheReturnsCachedTier() async {
        // Arrange
        userProfileStorageService.loadProfileReturnValue = makeProfile(
            userID: "user-1",
            cachedSubscription: SubscriptionAccessSnapshotFixtures.makeSnapshot(tier: .premium)
        )
        subscriptionService.refreshSubscriptionThrowableError = TestError.any

        // Act
        let result = await sut.refreshCurrentTierSourceState()

        // Assert
        XCTAssertEqual(result, .cache(.premium))
    }

    func testRefreshCurrentTierSourceStateWhenRefreshFailsWithoutCacheReturnsUnavailable() async {
        // Arrange
        userProfileStorageService.loadProfileReturnValue = makeProfile(userID: "user-1")
        subscriptionService.refreshSubscriptionThrowableError = TestError.any

        // Act
        let result = await sut.refreshCurrentTierSourceState()

        // Assert
        XCTAssertEqual(result, .unavailable)
    }
}

// MARK: - refreshCurrentSubscriptionSnapshot

extension SubscriptionAccessServiceTests {
    func testRefreshCurrentSubscriptionSnapshotWhenSnapshotChangesPostsNotification() async {
        // Arrange
        let previousSnapshot = SubscriptionAccessSnapshotFixtures.makeSnapshot(aiRequestsRemaining: 273, statusVersion: 42)
        let updatedSnapshot = SubscriptionAccessSnapshotFixtures.makeSnapshot(aiRequestsRemaining: 272, statusVersion: 42)
        userProfileStorageService.loadProfileReturnValue = makeProfile(
            userID: "user-1",
            cachedSubscription: previousSnapshot
        )
        subscriptionService.refreshSubscriptionReturnValue = updatedSnapshot
        let notificationExpectation = expectation(
            forNotification: .subscriptionAccessDidChange,
            object: nil,
            notificationCenter: notificationCenter
        ) { notification in
            notification.object as? SubscriptionAccessSnapshot == updatedSnapshot
                && notification.previousSubscriptionAccessSnapshot == previousSnapshot
        }

        // Act
        let result = await sut.refreshCurrentSubscriptionSnapshot()

        // Assert
        XCTAssertEqual(result, updatedSnapshot)
        await fulfillment(of: [notificationExpectation], timeout: 1)
    }
}

private extension SubscriptionAccessServiceTests {
    func makeProfile(
        userID: String,
        cachedSubscription: SubscriptionAccessSnapshot? = nil
    ) -> UserProfileDefaults {
        UserProfileDefaults(
            userId: userID,
            email: "jane@example.com",
            name: "Jane",
            currency: "USD",
            language: "en",
            cachedSubscription: cachedSubscription
        )
    }
}
