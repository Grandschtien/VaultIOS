import XCTest
@testable import Vault

final class SubscriptionAccessServiceTests: XCTestCase {
    func testCurrentTierFetchesAndCachesTierForCurrentUser() async {
        let profileService = ProfileContractServiceStub(
            results: [
                .success(makeProfile(id: "user-1", tier: "PLUS"))
            ]
        )
        let userProfileStorageService = UserProfileStorageServiceSpy(
            storedProfile: makeStoredProfile(userID: "user-1")
        )
        let sut = SubscriptionAccessService(
            profileService: profileService,
            userProfileStorageService: userProfileStorageService
        )

        let firstTier = await sut.currentTier()
        let secondTier = await sut.currentTier()
        let callsCount = await profileService.callsCount()

        XCTAssertEqual(firstTier, "PLUS")
        XCTAssertEqual(secondTier, "PLUS")
        XCTAssertEqual(callsCount, 1)
    }
}

extension SubscriptionAccessServiceTests {
    func testRefreshCurrentTierRefetchesAndReplacesCachedTier() async {
        let profileService = ProfileContractServiceStub(
            results: [
                .success(makeProfile(id: "user-1", tier: "PLUS")),
                .success(makeProfile(id: "user-1", tier: "PREMIUM"))
            ]
        )
        let sut = SubscriptionAccessService(
            profileService: profileService,
            userProfileStorageService: UserProfileStorageServiceSpy(
                storedProfile: makeStoredProfile(userID: "user-1")
            )
        )

        _ = await sut.currentTier()
        let refreshedTier = await sut.refreshCurrentTier()
        let resolvedTier = await sut.currentTier()
        let callsCount = await profileService.callsCount()

        XCTAssertEqual(refreshedTier, "PREMIUM")
        XCTAssertEqual(resolvedTier, "PREMIUM")
        XCTAssertEqual(callsCount, 2)
    }

    func testCurrentTierWhenUserChangesFetchesFreshTierForNewUser() async {
        let profileService = ProfileContractServiceStub(
            results: [
                .success(makeProfile(id: "user-1", tier: "PLUS")),
                .success(makeProfile(id: "user-2", tier: "PREMIUM"))
            ]
        )
        let userProfileStorageService = UserProfileStorageServiceSpy(
            storedProfile: makeStoredProfile(userID: "user-1")
        )
        let sut = SubscriptionAccessService(
            profileService: profileService,
            userProfileStorageService: userProfileStorageService
        )

        _ = await sut.currentTier()
        userProfileStorageService.storedProfile = makeStoredProfile(userID: "user-2")
        let secondTier = await sut.currentTier()
        let callsCount = await profileService.callsCount()

        XCTAssertEqual(secondTier, "PREMIUM")
        XCTAssertEqual(callsCount, 2)
    }
}

extension SubscriptionAccessServiceTests {
    func testCurrentTierWhenFetchFailsWithoutCacheReturnsRegular() async {
        let sut = SubscriptionAccessService(
            profileService: ProfileContractServiceStub(
                results: [.failure(StubError.any)]
            ),
            userProfileStorageService: UserProfileStorageServiceSpy(
                storedProfile: makeStoredProfile(userID: "user-1")
            )
        )

        let tier = await sut.currentTier()

        XCTAssertEqual(tier, "REGULAR")
    }

    func testLogoutNotificationClearsCachedTier() async {
        let profileService = ProfileContractServiceStub(
            results: [
                .success(makeProfile(id: "user-1", tier: "PLUS")),
                .success(makeProfile(id: "user-1", tier: "PLUS"))
            ]
        )
        let sut = SubscriptionAccessService(
            profileService: profileService,
            userProfileStorageService: UserProfileStorageServiceSpy(
                storedProfile: makeStoredProfile(userID: "user-1")
            )
        )

        _ = await sut.currentTier()
        NotificationCenter.default.post(name: .authSessionDidLogout, object: nil)
        await Task.yield()
        _ = await sut.currentTier()
        let callsCount = await profileService.callsCount()

        XCTAssertEqual(callsCount, 2)
    }
}

private extension SubscriptionAccessServiceTests {
    enum StubError: Error {
        case any
    }

    func makeProfile(
        id: String,
        tier: String
    ) -> ProfileResponseDTO {
        .init(
            id: id,
            email: "user@example.com",
            name: "User",
            currency: "USD",
            preferredLanguage: "en",
            tier: tier,
            tierValidUntil: nil
        )
    }

    func makeStoredProfile(userID: String) -> UserProfileDefaults {
        .init(
            userId: userID,
            email: "user@example.com",
            name: "User",
            currency: "USD",
            language: "en"
        )
    }
}

private actor ProfileContractServiceStub: ProfileContractServicing {
    private let results: [Result<ProfileResponseDTO, Error>]
    private var currentIndex = 0

    init(results: [Result<ProfileResponseDTO, Error>]) {
        self.results = results
    }

    func getProfile() async throws -> ProfileResponseDTO {
        let index = min(currentIndex, max(results.count - 1, 0))
        currentIndex += 1
        return try results[index].get()
    }

    func updateProfile(_ request: ProfileUpdateRequestDTO) async throws -> ProfileResponseDTO {
        throw SubscriptionAccessServiceTests.StubError.any
    }

    func callsCount() -> Int {
        currentIndex
    }
}

private final class UserProfileStorageServiceSpy: UserProfileStorageServiceProtocol, @unchecked Sendable {
    var storedProfile: UserProfileDefaults?

    init(storedProfile: UserProfileDefaults?) {
        self.storedProfile = storedProfile
    }

    func saveProfile(_ profile: UserProfileDefaults) {
        storedProfile = profile
    }

    func loadProfile() -> UserProfileDefaults? {
        storedProfile
    }

    func clearProfile() {
        storedProfile = nil
    }
}
