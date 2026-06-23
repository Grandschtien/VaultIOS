import XCTest
@testable import Vault

final class VaultWidgetSnapshotSyncServiceTests: XCTestCase {
    func testSyncSnapshotStoresTodayAndMonthTotalsAndReloadsTimelines() async {
        let summaryService = MainSummaryServiceSpy(
            results: [
                .success(
                    SummaryResponseDTO(
                        category: nil,
                        total: 45.2,
                        currency: "USD",
                        byCategory: nil
                    )
                ),
                .success(
                    SummaryResponseDTO(
                        category: nil,
                        total: 450.2,
                        currency: "USD",
                        byCategory: nil
                    )
                )
            ]
        )
        let storage = VylokWidgetSnapshotStoreSpy()
        let timelineReloader = VylokWidgetTimelineReloaderSpy()
        let profileStorage = UserProfileStorageSpy(
            profile: .init(
                userId: "user-id",
                email: "jane@example.com",
                name: "Jane",
                currency: "USD",
                language: "en"
            )
        )
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
            )
        )
        let snapshotDate = Date(timeIntervalSince1970: 1234)
        let sut = VylokWidgetSnapshotSyncService(
            summaryService: summaryService,
            userProfileStorageService: profileStorage,
            subscriptionAccessService: subscriptionAccessService,
            storage: storage,
            timelineReloader: timelineReloader,
            calendar: Calendar(identifier: .gregorian),
            now: { snapshotDate }
        )

        await sut.syncSnapshot()

        XCTAssertEqual(
            storage.savedSnapshots,
            [
                VylokWidgetSnapshot(
                    entitlementState: .subscribed,
                    todayAmount: 45.2,
                    todayCurrency: "USD",
                    monthAmount: 450.2,
                    monthCurrency: "USD",
                    updatedAt: snapshotDate
                )
            ]
        )
        XCTAssertEqual(timelineReloader.reloadCallsCount, 1)
        XCTAssertEqual(await summaryService.recordedParametersCount(), 2)
    }

    func testSyncSnapshotClearsSnapshotWhenUserIsSignedOut() async {
        let storage = VylokWidgetSnapshotStoreSpy(
            initialSnapshot: VylokWidgetSnapshot(
                entitlementState: .subscribed,
                todayAmount: 1,
                todayCurrency: "USD",
                monthAmount: 2,
                monthCurrency: "USD",
                updatedAt: Date()
            )
        )
        let timelineReloader = VylokWidgetTimelineReloaderSpy()
        let sut = VylokWidgetSnapshotSyncService(
            summaryService: MainSummaryServiceSpy(results: []),
            userProfileStorageService: UserProfileStorageSpy(profile: nil),
            subscriptionAccessService: SubscriptionAccessServiceSpy(currentSnapshot: nil),
            storage: storage,
            timelineReloader: timelineReloader
        )

        await sut.syncSnapshot()

        XCTAssertEqual(storage.clearCallsCount, 1)
        XCTAssertEqual(timelineReloader.reloadCallsCount, 1)
        XCTAssertTrue(storage.savedSnapshots.isEmpty)
    }

    func testSyncSnapshotStoresRegularStateAndPreservesFallbackValuesWhenSummaryFails() async {
        let summaryService = MainSummaryServiceSpy(
            results: [
                .failure(StubError.any),
                .failure(StubError.any)
            ]
        )
        let storage = VylokWidgetSnapshotStoreSpy(
            initialSnapshot: VylokWidgetSnapshot(
                entitlementState: .subscribed,
                todayAmount: 12.5,
                todayCurrency: "KZT",
                monthAmount: 98.4,
                monthCurrency: "KZT",
                updatedAt: Date(timeIntervalSince1970: 10)
            )
        )
        let timelineReloader = VylokWidgetTimelineReloaderSpy()
        let profileStorage = UserProfileStorageSpy(
            profile: .init(
                userId: "user-id",
                email: "jane@example.com",
                name: "Jane",
                currency: "USD",
                language: "en"
            )
        )
        let sut = VylokWidgetSnapshotSyncService(
            summaryService: summaryService,
            userProfileStorageService: profileStorage,
            subscriptionAccessService: SubscriptionAccessServiceSpy(
                currentSnapshot: .init(
                    tier: .regular,
                    status: .active,
                    paidAccessUntil: nil,
                    capabilities: [],
                    aiRequestsLimit: 0,
                    aiRequestsRemaining: 0,
                    statusVersion: 1
                )
            ),
            storage: storage,
            timelineReloader: timelineReloader
        )

        await sut.syncSnapshot()

        XCTAssertEqual(
            storage.savedSnapshots.last,
            VylokWidgetSnapshot(
                entitlementState: .regular,
                todayAmount: 12.5,
                todayCurrency: "KZT",
                monthAmount: 98.4,
                monthCurrency: "KZT",
                updatedAt: storage.savedSnapshots.last?.updatedAt ?? Date()
            )
        )
        XCTAssertEqual(timelineReloader.reloadCallsCount, 1)
    }

    func testClearSnapshotClearsStorageAndReloadsTimelines() {
        let storage = VylokWidgetSnapshotStoreSpy()
        let timelineReloader = VylokWidgetTimelineReloaderSpy()
        let sut = VylokWidgetSnapshotSyncService(
            summaryService: MainSummaryServiceSpy(results: []),
            userProfileStorageService: UserProfileStorageSpy(profile: nil),
            subscriptionAccessService: SubscriptionAccessServiceSpy(currentSnapshot: nil),
            storage: storage,
            timelineReloader: timelineReloader
        )

        sut.clearSnapshot()

        XCTAssertEqual(storage.clearCallsCount, 1)
        XCTAssertEqual(timelineReloader.reloadCallsCount, 1)
    }
}

private extension VaultWidgetSnapshotSyncServiceTests {
    enum StubError: Error {
        case any
    }
}

private actor MainSummaryServiceSpy: MainSummaryContractServicing {
    private var recordedParameters: [SummaryQueryParameters] = []
    private var results: [Result<SummaryResponseDTO, Error>]

    init(results: [Result<SummaryResponseDTO, Error>]) {
        self.results = results
    }

    func getSummary(parameters: SummaryQueryParameters) async throws -> SummaryResponseDTO {
        recordedParameters.append(parameters)

        guard results.isEmpty == false else {
            throw VylokWidgetSnapshotSyncServiceTests.StubError.any
        }

        let result = results.removeFirst()
        switch result {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }

    func getSummaryByCategory(
        id: String,
        parameters: SummaryQueryParameters
    ) async throws -> SummaryResponseDTO {
        try await getSummary(parameters: parameters)
    }

    func recordedParametersCount() -> Int {
        recordedParameters.count
    }
}

private final class VaultWidgetSnapshotStoreSpy: VylokWidgetSnapshotStoring, @unchecked Sendable {
    private var initialSnapshot: VylokWidgetSnapshot?
    private(set) var savedSnapshots: [VylokWidgetSnapshot] = []
    private(set) var clearCallsCount: Int = .zero

    init(initialSnapshot: VylokWidgetSnapshot? = nil) {
        self.initialSnapshot = initialSnapshot
    }

    func loadSnapshot() -> VylokWidgetSnapshot? {
        savedSnapshots.last ?? initialSnapshot
    }

    func saveSnapshot(_ snapshot: VylokWidgetSnapshot) {
        savedSnapshots.append(snapshot)
        initialSnapshot = snapshot
    }

    func clearSnapshot() {
        clearCallsCount += 1
        initialSnapshot = nil
    }
}

private final class VaultWidgetTimelineReloaderSpy: VylokWidgetTimelineReloading, @unchecked Sendable {
    private(set) var reloadCallsCount: Int = .zero

    func reloadTimelines() {
        reloadCallsCount += 1
    }
}

private final class UserProfileStorageSpy: UserProfileStorageServiceProtocol, @unchecked Sendable {
    private let profile: UserProfileDefaults?

    init(profile: UserProfileDefaults?) {
        self.profile = profile
    }

    func saveProfile(_ profile: UserProfileDefaults) {}

    func loadProfile() -> UserProfileDefaults? {
        profile
    }

    func clearProfile() {}
}

private final class SubscriptionAccessServiceSpy: SubscriptionAccessServicing, @unchecked Sendable {
    private let currentSnapshotValue: SubscriptionAccessSnapshot?
    private let refreshedSnapshotValue: SubscriptionAccessSnapshot?

    init(
        currentSnapshot: SubscriptionAccessSnapshot?,
        refreshedSnapshot: SubscriptionAccessSnapshot? = nil
    ) {
        currentSnapshotValue = currentSnapshot
        refreshedSnapshotValue = refreshedSnapshot
    }

    func currentTierState() async -> SubscriptionTierState {
        .resolved(currentSnapshotValue?.tier ?? .regular)
    }

    func refreshCurrentTierState() async -> SubscriptionTierState {
        .resolved(refreshedSnapshotValue?.tier ?? currentSnapshotValue?.tier ?? .regular)
    }

    func refreshCurrentTierSourceState() async -> SubscriptionTierRefreshState {
        .unavailable
    }

    func currentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot? {
        currentSnapshotValue
    }

    func refreshCurrentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot? {
        refreshedSnapshotValue
    }

    func startMonitoring() {}
}
