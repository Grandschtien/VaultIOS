import XCTest
@testable import Vylok

final class VaultWidgetSnapshotSyncServiceTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_783_166_400)

    private var summaryService: MainSummaryContractServicingMock!
    private var userProfileStorageService: UserProfileStorageServiceProtocolMock!
    private var subscriptionAccessService: SubscriptionAccessServicingMock!
    private var storage: VylokWidgetSnapshotStoringMock!
    private var timelineReloader: VylokWidgetTimelineReloadingMock!
    private var sut: VylokWidgetSnapshotSyncService!

    override func setUp() {
        super.setUp()
        summaryService = MainSummaryContractServicingMock()
        userProfileStorageService = UserProfileStorageServiceProtocolMock()
        subscriptionAccessService = SubscriptionAccessServicingMock()
        storage = VylokWidgetSnapshotStoringMock()
        timelineReloader = VylokWidgetTimelineReloadingMock()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let now = now
        sut = VylokWidgetSnapshotSyncService(
            summaryService: summaryService,
            userProfileStorageService: userProfileStorageService,
            subscriptionAccessService: subscriptionAccessService,
            storage: storage,
            timelineReloader: timelineReloader,
            calendar: calendar,
            now: { now }
        )
    }

    override func tearDown() {
        sut = nil
        timelineReloader = nil
        storage = nil
        subscriptionAccessService = nil
        userProfileStorageService = nil
        summaryService = nil
        super.tearDown()
    }
}

// MARK: - syncSnapshot

extension VaultWidgetSnapshotSyncServiceTests {
    func testSyncSnapshotWhenSummariesLoadSavesTodayAndMonthTotalsAndReloadsTimelines() async {
        // Arrange
        let todayStart = Date(timeIntervalSince1970: 1_783_123_200)
        userProfileStorageService.loadProfileReturnValue = UserProfileDefaults(
            userId: "user-1",
            email: "jane@example.com",
            name: "Jane",
            currency: "USD",
            language: "en"
        )
        subscriptionAccessService.currentSubscriptionSnapshotReturnValue =
            SubscriptionAccessSnapshotFixtures.makeSnapshot(tier: .premium)
        let monthStart = Date(timeIntervalSince1970: 1_782_864_000)
        // Both summaries are requested concurrently, so the requested periods are checked through the stubbed totals.
        summaryService.getSummaryParametersClosure = { parameters in
            SummaryResponseDTO(
                category: nil,
                total: parameters.from == todayStart ? 45.2 : parameters.from == monthStart ? 450.2 : .zero,
                currency: "USD",
                byCategory: nil
            )
        }

        // Act
        await sut.syncSnapshot()

        // Assert
        XCTAssertEqual(
            storage.saveSnapshotReceivedInvocations,
            [
                VylokWidgetSnapshot(
                    entitlementState: .subscribed,
                    todayAmount: 45.2,
                    todayCurrency: "USD",
                    monthAmount: 450.2,
                    monthCurrency: "USD",
                    updatedAt: now
                )
            ]
        )
        XCTAssertEqual(timelineReloader.reloadTimelinesCallsCount, 1)
    }

    func testSyncSnapshotWhenSummariesFailKeepsFallbackValuesAndResolvesRegularState() async {
        // Arrange
        userProfileStorageService.loadProfileReturnValue = UserProfileDefaults(
            userId: "user-1",
            email: "jane@example.com",
            name: "Jane",
            currency: "USD",
            language: "en"
        )
        subscriptionAccessService.currentSubscriptionSnapshotReturnValue = nil
        subscriptionAccessService.refreshCurrentSubscriptionSnapshotReturnValue = nil
        storage.loadSnapshotReturnValue = VylokWidgetSnapshot(
            entitlementState: .subscribed,
            todayAmount: 12.5,
            todayCurrency: "KZT",
            monthAmount: 98.4,
            monthCurrency: "KZT",
            updatedAt: Date(timeIntervalSince1970: 10)
        )
        summaryService.getSummaryParametersThrowableError = TestError.any

        // Act
        await sut.syncSnapshot()

        // Assert
        XCTAssertEqual(
            storage.saveSnapshotReceivedInvocations,
            [
                VylokWidgetSnapshot(
                    entitlementState: .regular,
                    todayAmount: 12.5,
                    todayCurrency: "KZT",
                    monthAmount: 98.4,
                    monthCurrency: "KZT",
                    updatedAt: now
                )
            ]
        )
        XCTAssertEqual(timelineReloader.reloadTimelinesCallsCount, 1)
    }

    func testSyncSnapshotWhenCurrentSnapshotIsMissingUsesRefreshedSnapshot() async {
        // Arrange
        userProfileStorageService.loadProfileReturnValue = UserProfileDefaults(
            userId: "user-1",
            email: "jane@example.com",
            name: "Jane",
            currency: "USD",
            language: "en"
        )
        subscriptionAccessService.currentSubscriptionSnapshotReturnValue = nil
        subscriptionAccessService.refreshCurrentSubscriptionSnapshotReturnValue =
            SubscriptionAccessSnapshotFixtures.makeSnapshot(tier: .premium)
        summaryService.getSummaryParametersThrowableError = TestError.any

        // Act
        await sut.syncSnapshot()

        // Assert
        XCTAssertEqual(
            storage.saveSnapshotReceivedInvocations,
            [
                VylokWidgetSnapshot(
                    entitlementState: .subscribed,
                    todayAmount: nil,
                    todayCurrency: nil,
                    monthAmount: nil,
                    monthCurrency: nil,
                    updatedAt: now
                )
            ]
        )
    }

    func testSyncSnapshotWhenUserIsSignedOutClearsSnapshot() async {
        // Arrange
        userProfileStorageService.loadProfileReturnValue = nil

        // Act
        await sut.syncSnapshot()

        // Assert
        XCTAssertEqual(storage.clearSnapshotCallsCount, 1)
        XCTAssertEqual(timelineReloader.reloadTimelinesCallsCount, 1)
        XCTAssertFalse(storage.saveSnapshotCalled)
        XCTAssertFalse(summaryService.getSummaryParametersCalled)
    }
}

// MARK: - clearSnapshot

extension VaultWidgetSnapshotSyncServiceTests {
    func testClearSnapshotClearsStorageAndReloadsTimelines() {
        // Act
        sut.clearSnapshot()

        // Assert
        XCTAssertEqual(storage.clearSnapshotCallsCount, 1)
        XCTAssertEqual(timelineReloader.reloadTimelinesCallsCount, 1)
    }
}
