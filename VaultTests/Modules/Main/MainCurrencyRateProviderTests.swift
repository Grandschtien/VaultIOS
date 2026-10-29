import XCTest
@testable import Vylok

final class MainCurrencyRateProviderTests: XCTestCase {
    private var currencyRateService: MainCurrencyRateContractServicingMock!
    private var profileStorage: UserProfileStorageServiceProtocolMock!

    override func setUp() {
        super.setUp()
        currencyRateService = MainCurrencyRateContractServicingMock()
        profileStorage = UserProfileStorageServiceProtocolMock()
    }

    override func tearDown() {
        profileStorage = nil
        currencyRateService = nil
        super.tearDown()
    }
}

// MARK: - synchronizeCurrencyRateOnLaunch

extension MainCurrencyRateProviderTests {
    func testSynchronizeCurrencyRateOnLaunchWhenCacheIsFreshSkipsRequest() async throws {
        // Arrange
        let sut = MainCurrencyRateProvider(
            currencyRateService: currencyRateService,
            userProfileStorageService: profileStorage,
            currentDateProvider: { Date(timeIntervalSince1970: 1_743_000_000) }
        )
        profileStorage.loadProfileReturnValue = UserProfileDefaultsFixtures.makeProfile(
            currencyRate: 1.5,
            currencyRateUpdatedAt: Date(timeIntervalSince1970: 1_742_999_000)
        )

        // Act
        try await sut.synchronizeCurrencyRateOnLaunch()

        // Assert
        XCTAssertFalse(currencyRateService.getCurrencyRateCurrencyCalled)
        XCTAssertFalse(profileStorage.saveProfileCalled)
    }

    func testSynchronizeCurrencyRateOnLaunchWhenCacheIsStaleRequestsAndPersistsNewRate() async throws {
        // Arrange
        let sut = MainCurrencyRateProvider(
            currencyRateService: currencyRateService,
            userProfileStorageService: profileStorage,
            currentDateProvider: { Date(timeIntervalSince1970: 1_743_000_000) }
        )
        profileStorage.loadProfileReturnValue = UserProfileDefaultsFixtures.makeProfile(
            currencyRate: 1.5,
            currencyRateUpdatedAt: Date(timeIntervalSince1970: 1_742_800_000)
        )
        currencyRateService.getCurrencyRateCurrencyReturnValue = CurrencyRateResponseDTO(
            currency: "USD",
            rateToUsd: 2.0,
            asOf: ""
        )

        // Act
        try await sut.synchronizeCurrencyRateOnLaunch()

        // Assert
        XCTAssertEqual(currencyRateService.getCurrencyRateCurrencyReceivedInvocations, ["USD"])
        XCTAssertEqual(
            profileStorage.saveProfileReceivedInvocations,
            [
                UserProfileDefaultsFixtures.makeProfile(
                    currencyRate: 2.0,
                    currencyRateUpdatedAt: Date(timeIntervalSince1970: 1_743_000_000)
                )
            ]
        )
    }

    func testSynchronizeCurrencyRateOnLaunchWhenRequestFailsAndCacheExistsKeepsPreviousValue() async throws {
        // Arrange
        let sut = MainCurrencyRateProvider(
            currencyRateService: currencyRateService,
            userProfileStorageService: profileStorage,
            currentDateProvider: { Date(timeIntervalSince1970: 1_743_000_000) }
        )
        profileStorage.loadProfileReturnValue = UserProfileDefaultsFixtures.makeProfile(
            currencyRate: 1.5,
            currencyRateUpdatedAt: Date(timeIntervalSince1970: 1_742_800_000)
        )
        currencyRateService.getCurrencyRateCurrencyThrowableError = TestError.any

        // Act
        try await sut.synchronizeCurrencyRateOnLaunch()

        // Assert
        XCTAssertEqual(currencyRateService.getCurrencyRateCurrencyReceivedInvocations, ["USD"])
        XCTAssertFalse(profileStorage.saveProfileCalled)
    }

    func testSynchronizeCurrencyRateOnLaunchWhenRequestFailsAndNoCacheRethrowsError() async {
        // Arrange
        let sut = MainCurrencyRateProvider(
            currencyRateService: currencyRateService,
            userProfileStorageService: profileStorage,
            currentDateProvider: { Date(timeIntervalSince1970: 1_743_000_000) }
        )
        profileStorage.loadProfileReturnValue = UserProfileDefaultsFixtures.makeProfile()
        currencyRateService.getCurrencyRateCurrencyThrowableError = TestError.any

        // Act
        let result = await Result { try await sut.synchronizeCurrencyRateOnLaunch() }

        // Assert
        XCTAssertEqual(result.failure as? TestError, .any)
    }

    func testSynchronizeCurrencyRateOnLaunchWhenProfileIsMissingThrowsMissingProfile() async {
        // Arrange
        let sut = MainCurrencyRateProvider(
            currencyRateService: currencyRateService,
            userProfileStorageService: profileStorage,
            currentDateProvider: { Date(timeIntervalSince1970: 1_743_000_000) }
        )

        // Act
        let result = await Result { try await sut.synchronizeCurrencyRateOnLaunch() }

        // Assert
        XCTAssertEqual(result.failure as? MainCurrencyRateProvider.Error, .missingProfile)
        XCTAssertFalse(currencyRateService.getCurrencyRateCurrencyCalled)
    }
}
