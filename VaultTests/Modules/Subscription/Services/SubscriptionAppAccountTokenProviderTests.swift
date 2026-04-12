import XCTest
@testable import Vault

final class SubscriptionAppAccountTokenProviderTests: XCTestCase {
    func testCurrentAppAccountTokenReturnsStoredBackendUserUUID() throws {
        let sut = SubscriptionAppAccountTokenProvider(
            userProfileStorageService: UserProfileStorageSpy(
                storedProfile: .init(
                    userId: "11111111-1111-1111-1111-111111111111",
                    email: "jane@example.com",
                    name: "Jane",
                    currency: "USD",
                    language: "en-US"
                )
            )
        )

        let token = try sut.currentAppAccountToken()

        XCTAssertEqual(token.uuidString, "11111111-1111-1111-1111-111111111111")
    }
}

extension SubscriptionAppAccountTokenProviderTests {
    func testCurrentAppAccountTokenWhenProfileMissingThrowsUnavailableError() {
        let sut = SubscriptionAppAccountTokenProvider(
            userProfileStorageService: UserProfileStorageSpy()
        )

        XCTAssertThrowsError(try sut.currentAppAccountToken()) { error in
            XCTAssertEqual(
                error.localizedDescription,
                L10n.subscriptionAccountTokenUnavailable
            )
        }
    }
}

extension SubscriptionAppAccountTokenProviderTests {
    func testCurrentAppAccountTokenWhenUserIDIsNotUUIDThrowsUnavailableError() {
        let sut = SubscriptionAppAccountTokenProvider(
            userProfileStorageService: UserProfileStorageSpy(
                storedProfile: .init(
                    userId: "not-a-uuid",
                    email: "jane@example.com",
                    name: "Jane",
                    currency: "USD",
                    language: "en-US"
                )
            )
        )

        XCTAssertThrowsError(try sut.currentAppAccountToken()) { error in
            XCTAssertEqual(
                error.localizedDescription,
                L10n.subscriptionAccountTokenUnavailable
            )
        }
    }
}

private final class UserProfileStorageSpy: UserProfileStorageServiceProtocol, @unchecked Sendable {
    private let storedProfile: UserProfileDefaults?

    init(storedProfile: UserProfileDefaults? = nil) {
        self.storedProfile = storedProfile
    }

    func saveProfile(_ profile: UserProfileDefaults) {}

    func loadProfile() -> UserProfileDefaults? {
        storedProfile
    }

    func clearProfile() {}
}
