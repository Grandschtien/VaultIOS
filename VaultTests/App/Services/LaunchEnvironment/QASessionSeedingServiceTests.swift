import XCTest
@testable import Vylok

final class QASessionSeedingServiceTests: XCTestCase {
    private var launchEnvironment: LaunchEnvironmentProvidingMock!
    private var tokenStorage: TokenStorageServiceProtocolMock!
    private var profileStorage: UserProfileStorageServiceProtocolMock!
    private var storage: KeyValueStorageMock!

    override func setUp() {
        super.setUp()
        launchEnvironment = LaunchEnvironmentProvidingMock()
        tokenStorage = TokenStorageServiceProtocolMock()
        profileStorage = UserProfileStorageServiceProtocolMock()
        storage = KeyValueStorageMock()
    }

    override func tearDown() {
        storage = nil
        profileStorage = nil
        tokenStorage = nil
        launchEnvironment = nil
        super.tearDown()
    }
}

// MARK: - seedSessionIfNeeded

extension QASessionSeedingServiceTests {
    func testSeedSessionIfNeededStoresTokenProfileAndOnboardingFlag() throws {
        // Arrange
        let sut = QASessionSeedingService(
            launchEnvironment: launchEnvironment,
            tokenStorageService: tokenStorage,
            userProfileStorageService: profileStorage,
            storage: storage
        )
        launchEnvironment.qaSession = """
        {"access_token":"access","refresh_token":"refresh","token_type":"Bearer","expires_in":900,\
        "user":{"id":"user-id","email":"qa@example.com","email_verified":true,"name":"QA",\
        "currency":"USD","preferred_language":"en","tier":"REGULAR"}}
        """

        // Act
        sut.seedSessionIfNeeded()

        // Assert
        let storageArguments = try XCTUnwrap(storage.setForKeyReceivedArguments)
        XCTAssertEqual(
            tokenStorage.setTokenReceivedInvocations,
            [AuthTokenDTO(accessToken: "access", refreshToken: "refresh", tokenType: "Bearer", expiresIn: 900)]
        )
        XCTAssertEqual(
            profileStorage.saveProfileReceivedInvocations,
            [
                UserProfileDefaults(
                    user: LoginResponseDTOFixtures.makeUser(
                        id: "user-id",
                        email: "qa@example.com",
                        name: "QA"
                    )
                )
            ]
        )
        XCTAssertEqual(storage.setForKeyCallsCount, 1)
        XCTAssertEqual(storageArguments.value as? Bool, true)
        XCTAssertEqual(storageArguments.key as? String, UserDefaultKeys.isOnboardingCompleted.rawValue)
    }

    func testSeedSessionIfNeededWhenSessionIsMissingStoresNothing() {
        // Arrange
        let sut = QASessionSeedingService(
            launchEnvironment: launchEnvironment,
            tokenStorageService: tokenStorage,
            userProfileStorageService: profileStorage,
            storage: storage
        )

        // Act
        sut.seedSessionIfNeeded()

        // Assert
        XCTAssertFalse(tokenStorage.setTokenCalled)
        XCTAssertFalse(profileStorage.saveProfileCalled)
        XCTAssertFalse(storage.setForKeyCalled)
    }

    func testSeedSessionIfNeededWhenSessionIsMalformedStoresNothing() {
        // Arrange
        let sut = QASessionSeedingService(
            launchEnvironment: launchEnvironment,
            tokenStorageService: tokenStorage,
            userProfileStorageService: profileStorage,
            storage: storage
        )
        launchEnvironment.qaSession = "{\"access_token\":\"access\"}"

        // Act
        sut.seedSessionIfNeeded()

        // Assert
        XCTAssertFalse(tokenStorage.setTokenCalled)
        XCTAssertFalse(profileStorage.saveProfileCalled)
        XCTAssertFalse(storage.setForKeyCalled)
    }
}
