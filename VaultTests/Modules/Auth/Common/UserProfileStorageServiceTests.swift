import XCTest
import Foundation
@testable import Vault

final class UserProfileStorageServiceTests: XCTestCase {
    private var sut: UserProfileStorageService!
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()

        suiteName = "UserProfileStorageServiceTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        sut = UserProfileStorageService(
            storage: UserDefaultsStorage(defaults: defaults)
        )
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        sut = nil
        super.tearDown()
    }
}

extension UserProfileStorageServiceTests {
    func testLoadProfileByDefaultReturnsNil() {
        XCTAssertNil(sut.loadProfile())
    }
}

extension UserProfileStorageServiceTests {
    func testSaveProfilePersistsValues() {
        let profile = UserProfileDefaults(
            userId: "344c3ab5-4360-4f02-af5f-d3cabea23cb0",
            email: "test3@example.com",
            name: "Jane",
            currency: "USD",
            language: "en-US"
        )

        sut.saveProfile(profile)

        XCTAssertEqual(sut.loadProfile(), profile)
    }
}

extension UserProfileStorageServiceTests {
    func testClearProfileRemovesSavedValue() {
        sut.saveProfile(
            UserProfileDefaults(
                userId: "344c3ab5-4360-4f02-af5f-d3cabea23cb0",
                email: "test3@example.com",
                name: "Jane",
                currency: "USD",
                language: "en-US"
            )
        )

        sut.clearProfile()

        XCTAssertNil(sut.loadProfile())
    }
}
