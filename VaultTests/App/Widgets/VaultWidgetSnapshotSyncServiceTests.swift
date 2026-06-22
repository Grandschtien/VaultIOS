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
        let storage = VaultWidgetSnapshotStoreSpy()
        let timelineReloader = VaultWidgetTimelineReloaderSpy()
        let snapshotDate = Date(timeIntervalSince1970: 1234)
        let sut = VaultWidgetSnapshotSyncService(
            summaryService: summaryService,
            storage: storage,
            timelineReloader: timelineReloader,
            calendar: Calendar(identifier: .gregorian),
            now: { snapshotDate }
        )

        await sut.syncSnapshot()

        XCTAssertEqual(
            storage.savedSnapshots,
            [
                VaultWidgetSnapshot(
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

    func testSyncSnapshotDoesNotStoreWhenSummaryRequestFails() async {
        let summaryService = MainSummaryServiceSpy(
            results: [
                .failure(StubError.any),
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
        let storage = VaultWidgetSnapshotStoreSpy()
        let timelineReloader = VaultWidgetTimelineReloaderSpy()
        let sut = VaultWidgetSnapshotSyncService(
            summaryService: summaryService,
            storage: storage,
            timelineReloader: timelineReloader
        )

        await sut.syncSnapshot()

        XCTAssertTrue(storage.savedSnapshots.isEmpty)
        XCTAssertEqual(timelineReloader.reloadCallsCount, 0)
    }

    func testClearSnapshotClearsStorageAndReloadsTimelines() {
        let storage = VaultWidgetSnapshotStoreSpy()
        let timelineReloader = VaultWidgetTimelineReloaderSpy()
        let sut = VaultWidgetSnapshotSyncService(
            summaryService: MainSummaryServiceSpy(results: []),
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
            throw VaultWidgetSnapshotSyncServiceTests.StubError.any
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

private final class VaultWidgetSnapshotStoreSpy: VaultWidgetSnapshotStoring, @unchecked Sendable {
    private(set) var savedSnapshots: [VaultWidgetSnapshot] = []
    private(set) var clearCallsCount: Int = .zero

    func loadSnapshot() -> VaultWidgetSnapshot? {
        savedSnapshots.last
    }

    func saveSnapshot(_ snapshot: VaultWidgetSnapshot) {
        savedSnapshots.append(snapshot)
    }

    func clearSnapshot() {
        clearCallsCount += 1
    }
}

private final class VaultWidgetTimelineReloaderSpy: VaultWidgetTimelineReloading, @unchecked Sendable {
    private(set) var reloadCallsCount: Int = .zero

    func reloadTimelines() {
        reloadCallsCount += 1
    }
}
