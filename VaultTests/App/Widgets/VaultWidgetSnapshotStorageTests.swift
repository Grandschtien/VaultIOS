import XCTest
@testable import Vault

final class VaultWidgetSnapshotStorageTests: XCTestCase {
    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var sut: VaultWidgetSnapshotStorage!

    override func setUp() {
        super.setUp()

        suiteName = "VaultWidgetSnapshotStorageTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults.removePersistentDomain(forName: suiteName)
        sut = VaultWidgetSnapshotStorage(userDefaults: userDefaults)
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
        let snapshot = VaultWidgetSnapshot(
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
            VaultWidgetSnapshot(
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
}
