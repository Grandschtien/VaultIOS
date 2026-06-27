import XCTest
@testable import Vylok

final class VaultWidgetSnapshotStorageTests: XCTestCase {
    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var sut: VylokWidgetSnapshotStorage!

    override func setUp() {
        super.setUp()

        suiteName = "VaultWidgetSnapshotStorageTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults.removePersistentDomain(forName: suiteName)
        sut = VylokWidgetSnapshotStorage(userDefaults: userDefaults)
    }

    override func tearDown() {
        if let suiteName {
            userDefaults?.removePersistentDomain(forName: suiteName)
        }
        suiteName = nil
        userDefaults = nil
        sut = nil
        super.tearDown()
    }
}

extension VaultWidgetSnapshotStorageTests {
    func testSaveAndLoadSnapshot() {
        let snapshot = VylokWidgetSnapshot(
            entitlementState: .subscribed,
            todayAmount: 45.2,
            todayCurrency: "USD",
            monthAmount: 450.2,
            monthCurrency: "USD",
            updatedAt: Date(timeIntervalSince1970: 123)
        )

        sut.saveSnapshot(snapshot)

        XCTAssertEqual(sut.loadSnapshot(), snapshot)
    }

    func testClearSnapshotRemovesStoredValue() {
        sut.saveSnapshot(
            VylokWidgetSnapshot(
                entitlementState: .regular,
                todayAmount: 1,
                todayCurrency: "USD",
                monthAmount: 2,
                monthCurrency: "USD",
                updatedAt: Date()
            )
        )

        sut.clearSnapshot()

        XCTAssertNil(sut.loadSnapshot())
    }

    func testLoadSnapshotMigratesLegacyPayload() throws {
        struct LegacyVaultWidgetSnapshot: Codable {
            let todayAmount: Double
            let todayCurrency: String
            let monthAmount: Double
            let monthCurrency: String
            let updatedAt: Date
        }

        let updatedAt = Date(timeIntervalSince1970: 321)
        let data = try JSONEncoder().encode(
            LegacyVaultWidgetSnapshot(
                todayAmount: 12,
                todayCurrency: "USD",
                monthAmount: 34,
                monthCurrency: "EUR",
                updatedAt: updatedAt
            )
        )
        userDefaults.set(
            data,
            forKey: VylokWidgetSharedConfiguration.snapshotStorageKey
        )

        XCTAssertEqual(
            sut.loadSnapshot(),
            VylokWidgetSnapshot(
                entitlementState: .subscribed,
                todayAmount: 12,
                todayCurrency: "USD",
                monthAmount: 34,
                monthCurrency: "EUR",
                updatedAt: updatedAt
            )
        )
    }
}
