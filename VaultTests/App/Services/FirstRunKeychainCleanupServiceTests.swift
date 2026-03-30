import XCTest
@testable import Vault

final class FirstRunKeychainCleanupServiceTests: XCTestCase {
    private var keychainClient: KeychainClientSpy!
    private var storage: InMemoryKeyValueStorage!
    private var sut: FirstRunKeychainCleanupService!

    override func setUp() {
        super.setUp()
        keychainClient = KeychainClientSpy()
        storage = InMemoryKeyValueStorage()
        sut = FirstRunKeychainCleanupService(
            keychainClient: keychainClient,
            storage: storage
        )
    }

    override func tearDown() {
        sut = nil
        storage = nil
        keychainClient = nil
        super.tearDown()
    }
}

extension FirstRunKeychainCleanupServiceTests {
    func testClearKeychainIfNeededWhenFirstRunClearsKeychainAndStoresFlag() {
        sut.clearKeychainIfNeeded()

        XCTAssertEqual(keychainClient.removeAllCallCount, 1)
        XCTAssertEqual(
            storage.get(Bool.self, forKey: UserDefaultKeys.isFirstRun.rawValue),
            false
        )
    }
}

extension FirstRunKeychainCleanupServiceTests {
    func testClearKeychainIfNeededWhenNotFirstRunSkipsCleanup() {
        storage.set(false, forKey: UserDefaultKeys.isFirstRun.rawValue)

        sut.clearKeychainIfNeeded()

        XCTAssertEqual(keychainClient.removeAllCallCount, 0)
    }
}

private final class KeychainClientSpy: KeychainClientProtocol {
    private(set) var removeAllCallCount = 0

    func set(_ data: Data, forAccount account: String, service: String) {}

    func getData(forAccount account: String, service: String) -> Data? {
        nil
    }

    func removeData(forAccount account: String, service: String) {}

    func removeAll() {
        removeAllCallCount += 1
    }
}

private final class InMemoryKeyValueStorage: KeyValueStorage {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var rawValues: [String: Data] = [:]

    func set<Value: Codable>(_ value: Value, forKey key: String) {
        guard let data = try? encoder.encode(value) else {
            return
        }

        rawValues[key] = data
    }

    func get<Value: Codable>(_ type: Value.Type, forKey key: String) -> Value? {
        guard let data = rawValues[key] else {
            return nil
        }

        return try? decoder.decode(type, from: data)
    }

    func removeValue(forKey key: String) {
        rawValues.removeValue(forKey: key)
    }
}
