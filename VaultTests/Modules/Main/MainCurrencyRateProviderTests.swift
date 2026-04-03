import XCTest
@testable import Vault

final class MainCurrencyRateProviderTests: XCTestCase {
    func testSynchronizeCurrencyRateOnLaunchWhenCacheIsFreshSkipsRequest() async throws {
        let now = Date(timeIntervalSince1970: 1_743_000_000)
        let profileStorage = UserProfileStorageSpy(
            profile: .init(
                userId: "1",
                email: "name@example.com",
                name: "Egor",
                currency: "USD",
                language: "en-US",
                currencyRate: 1.5,
                currencyRateUpdatedAt: Date(timeIntervalSince1970: 1_742_999_000)
            )
        )
        let service = CurrencyRateServiceSpy(
            result: .success(.init(currency: "USD", rateToUsd: 2.0, asOf: ""))
        )
        let sut = MainCurrencyRateProvider(
            currencyRateService: service,
            userProfileStorageService: profileStorage,
            currentDateProvider: { now }
        )

        try await sut.synchronizeCurrencyRateOnLaunch()

        let requestedCurrencies = await service.requestedCurrencies()
        XCTAssertTrue(requestedCurrencies.isEmpty)
        XCTAssertEqual(profileStorage.loadProfile()?.currencyRate, 1.5)
    }
}

extension MainCurrencyRateProviderTests {
    func testSynchronizeCurrencyRateOnLaunchWhenCacheIsStaleRequestsAndPersistsNewRate() async throws {
        let now = Date(timeIntervalSince1970: 1_743_000_000)
        let profileStorage = UserProfileStorageSpy(
            profile: .init(
                userId: "1",
                email: "name@example.com",
                name: "Egor",
                currency: "USD",
                language: "en-US",
                currencyRate: 1.5,
                currencyRateUpdatedAt: Date(timeIntervalSince1970: 1_742_800_000)
            )
        )
        let service = CurrencyRateServiceSpy(
            result: .success(.init(currency: "USD", rateToUsd: 2.0, asOf: ""))
        )
        let sut = MainCurrencyRateProvider(
            currencyRateService: service,
            userProfileStorageService: profileStorage,
            currentDateProvider: { now }
        )

        try await sut.synchronizeCurrencyRateOnLaunch()

        let requestedCurrencies = await service.requestedCurrencies()
        XCTAssertEqual(requestedCurrencies, ["USD"])
        XCTAssertEqual(profileStorage.loadProfile()?.currencyRate, 2.0)
        XCTAssertEqual(profileStorage.loadProfile()?.currencyRateUpdatedAt, now)
    }
}

extension MainCurrencyRateProviderTests {
    func testSynchronizeCurrencyRateOnLaunchWhenRequestFailsAndCacheExistsUsesPreviousValue() async throws {
        let now = Date(timeIntervalSince1970: 1_743_000_000)
        let profileStorage = UserProfileStorageSpy(
            profile: .init(
                userId: "1",
                email: "name@example.com",
                name: "Egor",
                currency: "USD",
                language: "en-US",
                currencyRate: 1.5,
                currencyRateUpdatedAt: Date(timeIntervalSince1970: 1_742_800_000)
            )
        )
        let service = CurrencyRateServiceSpy(result: .failure(StubError.any))
        let sut = MainCurrencyRateProvider(
            currencyRateService: service,
            userProfileStorageService: profileStorage,
            currentDateProvider: { now }
        )

        try await sut.synchronizeCurrencyRateOnLaunch()

        let requestedCurrencies = await service.requestedCurrencies()
        XCTAssertEqual(requestedCurrencies, ["USD"])
        XCTAssertEqual(profileStorage.loadProfile()?.currencyRate, 1.5)
    }
}

extension MainCurrencyRateProviderTests {
    func testSynchronizeCurrencyRateOnLaunchWhenRequestFailsAndNoCacheThrows() async {
        let now = Date(timeIntervalSince1970: 1_743_000_000)
        let profileStorage = UserProfileStorageSpy(
            profile: .init(
                userId: "1",
                email: "name@example.com",
                name: "Egor",
                currency: "USD",
                language: "en-US"
            )
        )
        let service = CurrencyRateServiceSpy(result: .failure(StubError.any))
        let sut = MainCurrencyRateProvider(
            currencyRateService: service,
            userProfileStorageService: profileStorage,
            currentDateProvider: { now }
        )

        do {
            try await sut.synchronizeCurrencyRateOnLaunch()
            XCTFail("Expected sync to throw when there is no cached rate")
        } catch {
            XCTAssertTrue(true)
        }
    }
}

private extension MainCurrencyRateProviderTests {
    enum StubError: Error {
        case any
    }
}

private actor CurrencyRateServiceSpy: MainCurrencyRateContractServicing {
    private let result: Result<CurrencyRateResponseDTO, Error>
    private var currencies: [String] = []

    init(result: Result<CurrencyRateResponseDTO, Error>) {
        self.result = result
    }

    func getCurrencyRate(currency: String) async throws -> CurrencyRateResponseDTO {
        currencies.append(currency)
        return try result.get()
    }

    func requestedCurrencies() -> [String] {
        currencies
    }
}

private final class UserProfileStorageSpy: UserProfileStorageServiceProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var profile: UserProfileDefaults?

    init(profile: UserProfileDefaults?) {
        self.profile = profile
    }

    func saveProfile(_ profile: UserProfileDefaults) {
        lock.withLock {
            self.profile = profile
        }
    }

    func loadProfile() -> UserProfileDefaults? {
        lock.withLock { profile }
    }

    func clearProfile() {
        lock.withLock {
            profile = nil
        }
    }
}

private extension NSLock {
    func withLock<T>(_ block: () -> T) -> T {
        lock()
        defer { unlock() }
        return block()
    }
}
