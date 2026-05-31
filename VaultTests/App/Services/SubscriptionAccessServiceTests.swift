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
            ],
            refreshResults: [
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

    func testRefreshCurrentTierSourceStateReturnsNetworkAndUpdatesCachedTier() async {
        let profileService = ProfileContractServiceStub(
            results: [
                .success(makeProfile(id: "user-1", tier: "REGULAR"))
            ],
            refreshResults: [
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
        let refreshedState = await sut.refreshCurrentTierSourceState()
        let resolvedTier = await sut.currentTier()

        XCTAssertEqual(refreshedState, .network("PREMIUM"))
        XCTAssertEqual(resolvedTier, "PREMIUM")
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
    func testCurrentTierStateWhenFetchFailsWithoutCacheReturnsUnavailable() async {
        let sut = SubscriptionAccessService(
            profileService: ProfileContractServiceStub(
                results: [.failure(StubError.any)]
            ),
            userProfileStorageService: UserProfileStorageServiceSpy(
                storedProfile: makeStoredProfile(userID: "user-1")
            )
        )

        let tierState = await sut.currentTierState()

        XCTAssertEqual(tierState, .unavailable)
    }

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

    func testRefreshCurrentTierSourceStateWhenRefreshFailsWithCacheReturnsCache() async {
        let profileService = ProfileContractServiceStub(
            results: [
                .success(makeProfile(id: "user-1", tier: "PLUS"))
            ],
            refreshResults: [
                .failure(StubError.any)
            ]
        )
        let sut = SubscriptionAccessService(
            profileService: profileService,
            userProfileStorageService: UserProfileStorageServiceSpy(
                storedProfile: makeStoredProfile(userID: "user-1")
            )
        )

        _ = await sut.currentTier()
        let refreshedState = await sut.refreshCurrentTierSourceState()

        XCTAssertEqual(refreshedState, .cache("PLUS"))
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
    private let refreshResults: [Result<ProfileResponseDTO, Error>]
    private var getProfileCallsCount = 0
    private var refreshProfileCallsCount = 0

    init(
        results: [Result<ProfileResponseDTO, Error>],
        refreshResults: [Result<ProfileResponseDTO, Error>]? = nil
    ) {
        self.results = results
        self.refreshResults = refreshResults ?? results
    }

    func getProfile() async throws -> ProfileResponseDTO {
        let index = min(getProfileCallsCount, max(results.count - 1, 0))
        getProfileCallsCount += 1
        return try results[index].get()
    }

    func refreshProfile() async throws -> ProfileResponseDTO {
        let index = min(refreshProfileCallsCount, max(refreshResults.count - 1, 0))
        refreshProfileCallsCount += 1
        return try refreshResults[index].get()
    }

    func updateProfile(_ request: ProfileUpdateRequestDTO) async throws -> ProfileResponseDTO {
        throw SubscriptionAccessServiceTests.StubError.any
    }

    func callsCount() -> Int {
        getProfileCallsCount + refreshProfileCallsCount
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
