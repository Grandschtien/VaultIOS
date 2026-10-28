import XCTest
@testable import Vylok

final class QASessionSeedingServiceTests: XCTestCase {
    private var tokenStorage: TokenStorageSpy!
    private var profileStorage: UserProfileStorageSpy!
    private var storage: InMemoryKeyValueStorage!

    override func setUp() {
        super.setUp()
        tokenStorage = TokenStorageSpy()
        profileStorage = UserProfileStorageSpy()
        storage = InMemoryKeyValueStorage()
    }

    override func tearDown() {
        storage = nil
        profileStorage = nil
        tokenStorage = nil
        super.tearDown()
    }
}

extension QASessionSeedingServiceTests {
    func testSeedSessionIfNeededStoresTokenProfileAndOnboardingFlag() {
        let sut = makeSUT(environment: ["VAULT_QA_MODE": "1", "VAULT_QA_SESSION": Self.loginResponse])

        sut.seedSessionIfNeeded()

        XCTAssertEqual(tokenStorage.token?.accessToken, "access")
        XCTAssertEqual(tokenStorage.token?.refreshToken, "refresh")
        XCTAssertEqual(tokenStorage.token?.expiresIn, 900)
        XCTAssertEqual(profileStorage.profile?.userId, "user-id")
        XCTAssertEqual(profileStorage.profile?.currency, "USD")
        XCTAssertEqual(storage.get(Bool.self, forKey: UserDefaultKeys.isOnboardingCompleted.rawValue), true)
    }
}

extension QASessionSeedingServiceTests {
    func testSeedSessionIfNeededSkipsWhenSessionIsMissing() {
        let sut = makeSUT(environment: ["VAULT_QA_MODE": "1"])

        sut.seedSessionIfNeeded()

        assertNothingStored()
    }

    func testSeedSessionIfNeededSkipsWhenQAModeIsOff() {
        let sut = makeSUT(environment: ["VAULT_QA_SESSION": Self.loginResponse])

        sut.seedSessionIfNeeded()

        assertNothingStored()
    }

    func testSeedSessionIfNeededSkipsWhenOverridesAreNotAllowed() {
        let sut = makeSUT(
            environment: ["VAULT_QA_MODE": "1", "VAULT_QA_SESSION": Self.loginResponse],
            isOverrideAllowed: false
        )

        sut.seedSessionIfNeeded()

        assertNothingStored()
    }

    func testSeedSessionIfNeededSkipsMalformedSession() {
        let sut = makeSUT(environment: ["VAULT_QA_MODE": "1", "VAULT_QA_SESSION": "{\"access_token\":\"access\"}"])

        sut.seedSessionIfNeeded()

        assertNothingStored()
    }
}

private extension QASessionSeedingServiceTests {
    static let loginResponse = """
    {"access_token":"access","refresh_token":"refresh","token_type":"Bearer","expires_in":900,\
    "user":{"id":"user-id","email":"qa@example.com","email_verified":true,"name":"QA",\
    "currency":"USD","preferred_language":"en","tier":"REGULAR"}}
    """

    func makeSUT(
        environment: [String: String],
        isOverrideAllowed: Bool = true
    ) -> QASessionSeedingService {
        QASessionSeedingService(
            launchEnvironment: LaunchEnvironmentProvider(
                environment: environment,
                isOverrideAllowed: isOverrideAllowed
            ),
            tokenStorageService: tokenStorage,
            userProfileStorageService: profileStorage,
            storage: storage
        )
    }

    func assertNothingStored(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNil(tokenStorage.token, file: file, line: line)
        XCTAssertNil(profileStorage.profile, file: file, line: line)
        XCTAssertNil(
            storage.get(Bool.self, forKey: UserDefaultKeys.isOnboardingCompleted.rawValue),
            file: file,
            line: line
        )
    }
}

private final class TokenStorageSpy: TokenStorageServiceProtocol, @unchecked Sendable {
    private(set) var token: AuthTokenDTO?

    func setToken(_ token: AuthTokenDTO) {
        self.token = token
    }

    func getToken() -> AuthTokenDTO? {
        token
    }

    func removeToken() {
        token = nil
    }
}

private final class UserProfileStorageSpy: UserProfileStorageServiceProtocol, @unchecked Sendable {
    private(set) var profile: UserProfileDefaults?

    func saveProfile(_ profile: UserProfileDefaults) {
        self.profile = profile
    }

    func loadProfile() -> UserProfileDefaults? {
        profile
    }

    func clearProfile() {
        profile = nil
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
