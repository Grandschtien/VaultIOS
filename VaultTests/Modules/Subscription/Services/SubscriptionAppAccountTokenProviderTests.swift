import XCTest
@testable import Vylok

final class SubscriptionAppAccountTokenProviderTests: XCTestCase {
    private var userProfileStorageService: UserProfileStorageServiceProtocolMock!

    override func setUp() {
        super.setUp()
        userProfileStorageService = UserProfileStorageServiceProtocolMock()
    }

    override func tearDown() {
        userProfileStorageService = nil
        super.tearDown()
    }
}

// MARK: - currentAppAccountToken

extension SubscriptionAppAccountTokenProviderTests {
    func testCurrentAppAccountTokenReturnsStoredBackendUserUUID() throws {
        // Arrange
        let sut = SubscriptionAppAccountTokenProvider(userProfileStorageService: userProfileStorageService)
        userProfileStorageService.loadProfileReturnValue = UserProfileDefaultsFixtures.makeProfile(
            userId: "11111111-1111-1111-1111-111111111111"
        )

        // Act
        let token = try sut.currentAppAccountToken()

        // Assert
        XCTAssertEqual(token, UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
    }

    func testCurrentAppAccountTokenWhenProfileMissingThrowsUnavailableError() {
        // Arrange
        let sut = SubscriptionAppAccountTokenProvider(userProfileStorageService: userProfileStorageService)

        // Act & Assert
        XCTAssertThrowsError(try sut.currentAppAccountToken()) { error in
            XCTAssertEqual(error.localizedDescription, L10n.subscriptionAccountTokenUnavailable)
        }
    }

    func testCurrentAppAccountTokenWhenUserIDIsNotUUIDThrowsUnavailableError() {
        // Arrange
        let sut = SubscriptionAppAccountTokenProvider(userProfileStorageService: userProfileStorageService)
        userProfileStorageService.loadProfileReturnValue = UserProfileDefaultsFixtures.makeProfile(userId: "not-a-uuid")

        // Act & Assert
        XCTAssertThrowsError(try sut.currentAppAccountToken()) { error in
            XCTAssertEqual(error.localizedDescription, L10n.subscriptionAccountTokenUnavailable)
        }
    }
}
