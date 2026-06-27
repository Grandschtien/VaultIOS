import XCTest
import UIKit
@testable import Vylok

final class SubscriptionAccessServiceTests: XCTestCase {
    func testCurrentTierFetchesAndCachesTierForCurrentUser() async {
        let subscriptionService = SubscriptionAccessContractServiceStub(
            results: [
                .success(makeSnapshot(tier: "PREMIUM"))
            ]
        )
        let userProfileStorageService = UserProfileStorageServiceSpy(
            storedProfile: makeStoredProfile(userID: "user-1")
        )
        let sut = SubscriptionAccessService(
            subscriptionService: subscriptionService,
            userProfileStorageService: userProfileStorageService
        )

        let firstTier = await sut.currentTier()
        let secondTier = await sut.currentTier()
        let callsCount = await subscriptionService.callsCount()

        XCTAssertEqual(firstTier, .premium)
        XCTAssertEqual(secondTier, .premium)
        XCTAssertEqual(callsCount, 1)
        XCTAssertEqual(
            userProfileStorageService.storedProfile?.cachedSubscription,
            makeSnapshot(tier: "PREMIUM")
        )
    }
}

extension SubscriptionAccessServiceTests {
    func testRefreshCurrentSubscriptionSnapshotPostsNotificationWhenSnapshotChanges() async {
        let notificationCenter = NotificationCenter()
        let subscriptionService = SubscriptionAccessContractServiceStub(
            results: [
                .success(
                    makeSnapshot(
                        tier: "PREMIUM",
                        aiRequestsRemaining: 273,
                        statusVersion: 42
                    )
                )
            ],
            refreshResults: [
                .success(
                    makeSnapshot(
                        tier: "PREMIUM",
                        aiRequestsRemaining: 272,
                        statusVersion: 42
                    )
                )
            ]
        )
        let sut = SubscriptionAccessService(
            subscriptionService: subscriptionService,
            userProfileStorageService: UserProfileStorageServiceSpy(
                storedProfile: makeStoredProfile(userID: "user-1")
            ),
            notificationCenter: notificationCenter
        )

        _ = await sut.currentSubscriptionSnapshot()

        let expectation = expectation(description: "Subscription access changed")
        var receivedSnapshot: SubscriptionAccessSnapshot?
        let token = notificationCenter.addObserver(
            forName: .subscriptionAccessDidChange,
            object: nil,
            queue: .main
        ) { notification in
            receivedSnapshot = notification.object as? SubscriptionAccessSnapshot
            expectation.fulfill()
        }
        defer {
            notificationCenter.removeObserver(token)
        }

        let refreshedSnapshot = await sut.refreshCurrentSubscriptionSnapshot()

        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(refreshedSnapshot?.aiRequestsRemaining, 272)
        XCTAssertEqual(receivedSnapshot?.aiRequestsRemaining, 272)
    }
}

extension SubscriptionAccessServiceTests {
    func testCurrentTierUsesPersistedLastKnownStateWhenRefreshFailsAfterRelaunch() async {
        let userProfileStorageService = UserProfileStorageServiceSpy(
            storedProfile: makeStoredProfile(userID: "user-1")
        )
        let firstService = SubscriptionAccessService(
            subscriptionService: SubscriptionAccessContractServiceStub(
                results: [
                    .success(makeSnapshot(tier: "PREMIUM", statusVersion: 42))
                ]
            ),
            userProfileStorageService: userProfileStorageService
        )

        _ = await firstService.currentTier()

        let relaunchedService = SubscriptionAccessService(
            subscriptionService: SubscriptionAccessContractServiceStub(
                results: [.failure(StubError.any)]
            ),
            userProfileStorageService: userProfileStorageService
        )

        let tier = await relaunchedService.currentTier()

        XCTAssertEqual(tier, .premium)
    }

    func testCurrentTierRefreshesWhenCachedExpirationPassed() async {
        let now = Date(timeIntervalSince1970: 1_775_001_600)
        let subscriptionService = SubscriptionAccessContractServiceStub(
            results: [
                .success(
                    makeSnapshot(
                        tier: "PREMIUM",
                        paidAccessUntil: now.addingTimeInterval(-1),
                        statusVersion: 41
                    )
                )
            ],
            refreshResults: [
                .success(makeSnapshot(tier: "REGULAR", statusVersion: 42))
            ]
        )
        let sut = SubscriptionAccessService(
            subscriptionService: subscriptionService,
            userProfileStorageService: UserProfileStorageServiceSpy(
                storedProfile: makeStoredProfile(userID: "user-1")
            ),
            currentDate: { now }
        )

        let firstTier = await sut.currentTier()
        let secondTier = await sut.currentTier()
        let callsCount = await subscriptionService.callsCount()

        XCTAssertEqual(firstTier, .premium)
        XCTAssertEqual(secondTier, .regular)
        XCTAssertEqual(callsCount, 2)
    }

    func testRefreshCurrentTierRefetchesAndReplacesCachedTier() async {
        let subscriptionService = SubscriptionAccessContractServiceStub(
            results: [
                .success(makeSnapshot(tier: "REGULAR", statusVersion: 41))
            ],
            refreshResults: [
                .success(makeSnapshot(tier: "PREMIUM", statusVersion: 42))
            ]
        )
        let sut = SubscriptionAccessService(
            subscriptionService: subscriptionService,
            userProfileStorageService: UserProfileStorageServiceSpy(
                storedProfile: makeStoredProfile(userID: "user-1")
            )
        )

        _ = await sut.currentTier()
        let refreshedTier = await sut.refreshCurrentTier()
        let resolvedTier = await sut.currentTier()
        let callsCount = await subscriptionService.callsCount()

        XCTAssertEqual(refreshedTier, .premium)
        XCTAssertEqual(resolvedTier, .premium)
        XCTAssertEqual(callsCount, 2)
    }

    func testRefreshCurrentTierSourceStateReturnsCacheWhenResponseVersionIsOlder() async {
        let subscriptionService = SubscriptionAccessContractServiceStub(
            results: [
                .success(makeSnapshot(tier: "PREMIUM", statusVersion: 42))
            ],
            refreshResults: [
                .success(makeSnapshot(tier: "REGULAR", statusVersion: 41))
            ]
        )
        let userProfileStorageService = UserProfileStorageServiceSpy(
            storedProfile: makeStoredProfile(userID: "user-1")
        )
        let sut = SubscriptionAccessService(
            subscriptionService: subscriptionService,
            userProfileStorageService: userProfileStorageService
        )

        _ = await sut.currentTier()
        let refreshedState = await sut.refreshCurrentTierSourceState()
        let resolvedTier = await sut.currentTier()

        XCTAssertEqual(refreshedState, .cache(.premium))
        XCTAssertEqual(resolvedTier, .premium)
        XCTAssertEqual(
            userProfileStorageService.storedProfile?.cachedSubscription,
            makeSnapshot(tier: "PREMIUM", statusVersion: 42)
        )
    }

    func testRefreshCurrentSubscriptionSnapshotAppliesEqualStatusVersion() async {
        let subscriptionService = SubscriptionAccessContractServiceStub(
            results: [
                .success(makeSnapshot(tier: "REGULAR", statusVersion: 42))
            ],
            refreshResults: [
                .success(
                    makeSnapshot(
                        tier: "PREMIUM",
                        capabilities: ["analytics"],
                        statusVersion: 42
                    )
                )
            ]
        )
        let sut = SubscriptionAccessService(
            subscriptionService: subscriptionService,
            userProfileStorageService: UserProfileStorageServiceSpy(
                storedProfile: makeStoredProfile(userID: "user-1")
            )
        )

        _ = await sut.currentSubscriptionSnapshot()
        let refreshedSnapshot = await sut.refreshCurrentSubscriptionSnapshot()

        XCTAssertEqual(refreshedSnapshot?.tier, .premium)
        XCTAssertEqual(refreshedSnapshot?.capabilities, [.analytics])
        XCTAssertEqual(refreshedSnapshot?.statusVersion, 42)
    }

    func testCurrentTierWhenUserChangesFetchesFreshTierForNewUser() async {
        let subscriptionService = SubscriptionAccessContractServiceStub(
            results: [
                .success(makeSnapshot(tier: "REGULAR", statusVersion: 41)),
                .success(makeSnapshot(tier: "PREMIUM", statusVersion: 42))
            ]
        )
        let userProfileStorageService = UserProfileStorageServiceSpy(
            storedProfile: makeStoredProfile(userID: "user-1")
        )
        let sut = SubscriptionAccessService(
            subscriptionService: subscriptionService,
            userProfileStorageService: userProfileStorageService
        )

        _ = await sut.currentTier()
        userProfileStorageService.storedProfile = makeStoredProfile(userID: "user-2")
        let secondTier = await sut.currentTier()
        let callsCount = await subscriptionService.callsCount()

        XCTAssertEqual(secondTier, .premium)
        XCTAssertEqual(callsCount, 2)
    }
}

extension SubscriptionAccessServiceTests {
    func testStartMonitoringRefreshesOnLaunchAndForeground() async {
        let notificationCenter = NotificationCenter()
        let subscriptionService = SubscriptionAccessContractServiceStub(
            results: [.success(makeSnapshot(tier: "PREMIUM", statusVersion: 41))],
            refreshResults: [
                .success(makeSnapshot(tier: "PREMIUM", statusVersion: 42)),
                .success(makeSnapshot(tier: "PREMIUM", statusVersion: 43))
            ]
        )
        let sut = SubscriptionAccessService(
            subscriptionService: subscriptionService,
            userProfileStorageService: UserProfileStorageServiceSpy(
                storedProfile: makeStoredProfile(userID: "user-1")
            ),
            notificationCenter: notificationCenter
        )

        sut.startMonitoring()
        await waitUntilCallsCount(1, for: subscriptionService)

        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        await waitUntilCallsCount(2, for: subscriptionService)

        let callsCount = await subscriptionService.callsCount()

        XCTAssertEqual(callsCount, 2)
    }

    func testStartMonitoringRefreshesWhenPaidAccessDateIsReached() async {
        let subscriptionService = SubscriptionAccessContractServiceStub(
            results: [.success(makeSnapshot(tier: "PREMIUM", statusVersion: 41))],
            refreshResults: [
                .success(
                    makeSnapshot(
                        tier: "PREMIUM",
                        paidAccessUntil: Date().addingTimeInterval(0.05),
                        statusVersion: 42
                    )
                ),
                .success(makeSnapshot(tier: "REGULAR", statusVersion: 43))
            ]
        )
        let sut = SubscriptionAccessService(
            subscriptionService: subscriptionService,
            userProfileStorageService: UserProfileStorageServiceSpy(
                storedProfile: makeStoredProfile(userID: "user-1")
            )
        )

        sut.startMonitoring()
        await waitUntilCallsCount(2, for: subscriptionService)

        let tier = await sut.currentTier()

        XCTAssertEqual(tier, .regular)
    }

    func testCurrentTierStateWhenFetchFailsWithoutCacheReturnsUnavailable() async {
        let sut = SubscriptionAccessService(
            subscriptionService: SubscriptionAccessContractServiceStub(
                results: [.failure(StubError.any)]
            ),
            userProfileStorageService: UserProfileStorageServiceSpy(
                storedProfile: makeStoredProfile(userID: "user-1")
            )
        )

        let tierState = await sut.currentTierState()

        XCTAssertEqual(tierState, .unavailable)
    }

    func testCurrentTierWhenFetchFailsWithoutCacheReturnsRegular() async {
        let sut = SubscriptionAccessService(
            subscriptionService: SubscriptionAccessContractServiceStub(
                results: [.failure(StubError.any)]
            ),
            userProfileStorageService: UserProfileStorageServiceSpy(
                storedProfile: makeStoredProfile(userID: "user-1")
            )
        )

        let tier = await sut.currentTier()

        XCTAssertEqual(tier, .regular)
    }

    func testRefreshCurrentTierSourceStateWhenRefreshFailsWithCacheReturnsCache() async {
        let subscriptionService = SubscriptionAccessContractServiceStub(
            results: [
                .success(makeSnapshot(tier: "PREMIUM", statusVersion: 42))
            ],
            refreshResults: [
                .failure(StubError.any)
            ]
        )
        let sut = SubscriptionAccessService(
            subscriptionService: subscriptionService,
            userProfileStorageService: UserProfileStorageServiceSpy(
                storedProfile: makeStoredProfile(userID: "user-1")
            )
        )

        _ = await sut.currentTier()
        let refreshedState = await sut.refreshCurrentTierSourceState()

        XCTAssertEqual(refreshedState, .cache(.premium))
    }

    func testLogoutNotificationClearsCachedTier() async {
        let subscriptionService = SubscriptionAccessContractServiceStub(
            results: [
                .success(makeSnapshot(tier: "PREMIUM", statusVersion: 42)),
                .success(makeSnapshot(tier: "REGULAR", statusVersion: 43))
            ]
        )
        let userProfileStorageService = UserProfileStorageServiceSpy(
            storedProfile: makeStoredProfile(userID: "user-1")
        )
        let sut = SubscriptionAccessService(
            subscriptionService: subscriptionService,
            userProfileStorageService: userProfileStorageService
        )

        _ = await sut.currentTier()
        NotificationCenter.default.post(name: .authSessionDidLogout, object: nil)
        await Task.yield()

        userProfileStorageService.storedProfile = makeStoredProfile(userID: "user-1")
        _ = await sut.currentTier()
        let callsCount = await subscriptionService.callsCount()

        XCTAssertEqual(callsCount, 2)
    }
}

private extension SubscriptionAccessServiceTests {
    enum StubError: Error {
        case any
    }

    func makeSnapshot(
        tier: String,
        status: String = "active",
        paidAccessUntil: Date? = nil,
        capabilities: [String] = ["analytics", "custom_date_range", "ai_input"],
        aiRequestsLimit: Int = 300,
        aiRequestsRemaining: Int = 273,
        statusVersion: Int = 42
    ) -> SubscriptionAccessSnapshot {
        .init(
            tier: tier == "REGULAR" ? .regular : .premium,
            status: switch status {
            case "cancel_pending":
                .cancelPending
            case "expired":
                .expired
            case "revoked":
                .revoked
            default:
                .active
            },
            paidAccessUntil: paidAccessUntil,
            capabilities: capabilities.compactMap {
                switch $0 {
                case "analytics":
                    .analytics
                case "custom_date_range":
                    .customDateRange
                case "ai_input":
                    .aiInput
                default:
                    nil
                }
            },
            aiRequestsLimit: aiRequestsLimit,
            aiRequestsRemaining: aiRequestsRemaining,
            statusVersion: statusVersion
        )
    }

    func makeStoredProfile(
        userID: String,
        cachedSubscription: SubscriptionAccessSnapshot? = nil
    ) -> UserProfileDefaults {
        .init(
            userId: userID,
            email: "user@example.com",
            name: "User",
            currency: "USD",
            language: "en",
            cachedSubscription: cachedSubscription
        )
    }

    func waitUntilCallsCount(
        _ expectedCount: Int,
        for subscriptionService: SubscriptionAccessContractServiceStub
    ) async {
        for _ in 0..<200 {
            if await subscriptionService.callsCount() >= expectedCount {
                return
            }

            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTFail("Expected calls count to reach \(expectedCount)")
    }
}

private actor SubscriptionAccessContractServiceStub: SubscriptionAccessContractServicing {
    private let results: [Result<SubscriptionAccessSnapshot, Error>]
    private let refreshResults: [Result<SubscriptionAccessSnapshot, Error>]
    private var getSubscriptionCallsCount = 0
    private var refreshSubscriptionCallsCount = 0

    init(
        results: [Result<SubscriptionAccessSnapshot, Error>],
        refreshResults: [Result<SubscriptionAccessSnapshot, Error>]? = nil
    ) {
        self.results = results
        self.refreshResults = refreshResults ?? results
    }

    func getSubscription() async throws -> SubscriptionAccessSnapshot {
        let index = min(getSubscriptionCallsCount, max(results.count - 1, 0))
        getSubscriptionCallsCount += 1
        return try results[index].get()
    }

    func refreshSubscription() async throws -> SubscriptionAccessSnapshot {
        let index = min(refreshSubscriptionCallsCount, max(refreshResults.count - 1, 0))
        refreshSubscriptionCallsCount += 1
        return try refreshResults[index].get()
    }

    func callsCount() -> Int {
        getSubscriptionCallsCount + refreshSubscriptionCallsCount
    }
}

private final class UserProfileStorageServiceSpy: UserProfileStorageServiceProtocol, @unchecked Sendable {
    var storedProfile: UserProfileDefaults?

    init(storedProfile: UserProfileDefaults?) {
        self.storedProfile = storedProfile
    }

    func saveProfile(_ profile: UserProfileDefaults) {
        storedProfile = profile
    }

    func loadProfile() -> UserProfileDefaults? {
        storedProfile
    }

    func clearProfile() {
        storedProfile = nil
    }
}
