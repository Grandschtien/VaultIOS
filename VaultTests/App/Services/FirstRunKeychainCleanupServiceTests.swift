import XCTest
@testable import Vylok

final class FirstRunKeychainCleanupServiceTests: XCTestCase {
    private var keychainClient: KeychainClientProtocolMock!
    private var storage: KeyValueStorageMock!

    override func setUp() {
        super.setUp()
        keychainClient = KeychainClientProtocolMock()
        storage = KeyValueStorageMock()
    }

    override func tearDown() {
        storage = nil
        keychainClient = nil
        super.tearDown()
    }
}

// MARK: - clearKeychainIfNeeded

extension FirstRunKeychainCleanupServiceTests {
    func testClearKeychainIfNeededWhenFirstRunClearsKeychainAndStoresFlag() throws {
        // Arrange
        let sut = FirstRunKeychainCleanupService(
            keychainClient: keychainClient,
            storage: storage
        )

        // Act
        sut.clearKeychainIfNeeded()

        // Assert
        let arguments = try XCTUnwrap(storage.setForKeyReceivedArguments)
        XCTAssertEqual(keychainClient.removeAllCallsCount, 1)
        XCTAssertEqual(storage.setForKeyCallsCount, 1)
        XCTAssertEqual(arguments.value as? Bool, false)
        XCTAssertEqual(arguments.key as? String, UserDefaultKeys.isFirstRun.rawValue)
    }

    func testClearKeychainIfNeededWhenNotFirstRunSkipsCleanup() {
        // Arrange
        let sut = FirstRunKeychainCleanupService(
            keychainClient: keychainClient,
            storage: storage
        )
        storage.getForKeyReturnValue = false

        // Act
        sut.clearKeychainIfNeeded()

        // Assert
        XCTAssertFalse(keychainClient.removeAllCalled)
        XCTAssertFalse(storage.setForKeyCalled)
    }
}
