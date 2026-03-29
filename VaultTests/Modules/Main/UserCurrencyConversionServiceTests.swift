import XCTest
@testable import Vault

final class UserCurrencyConversionServiceTests: XCTestCase {
    func testConvertUsdAmountWhenProfileHasRateConvertsIntoPreferredCurrency() {
        let profileStorage = UserProfileStorageSpy(
            profile: .init(
                userId: "user-1",
                email: "user@example.com",
                name: "Test User",
                currency: "EUR",
                language: "en-US",
                currencyRate: 2.0
            )
        )
        let sut = UserCurrencyConversionService(userProfileStorageService: profileStorage)

        let converted = sut.convertUsdAmount(10)

        XCTAssertEqual(converted.amount, 5.0)
        XCTAssertEqual(converted.currency, "EUR")
    }
}

extension UserCurrencyConversionServiceTests {
    func testConvertUsdAmountWhenProfileMissingFallsBackToUsd() {
        let sut = UserCurrencyConversionService(
            userProfileStorageService: UserProfileStorageSpy(profile: nil)
        )

        let converted = sut.convertUsdAmount(10)

        XCTAssertEqual(converted.amount, 10)
        XCTAssertEqual(converted.currency, "USD")
    }
}

extension UserCurrencyConversionServiceTests {
    func testConvertExpenseWhenCurrencyIsUsdConvertsToPreferredCurrency() {
        let profileStorage = UserProfileStorageSpy(
            profile: .init(
                userId: "user-1",
                email: "user@example.com",
                name: "Test User",
                currency: "KZT",
                language: "ru",
                currencyRate: 2.0
            )
        )
        let sut = UserCurrencyConversionService(userProfileStorageService: profileStorage)

        let converted = sut.convertExpense(
            amount: 7.4,
            currency: "USD"
        )

        XCTAssertEqual(converted.amount, 3.7)
        XCTAssertEqual(converted.currency, "KZT")
    }
}

extension UserCurrencyConversionServiceTests {
    func testConvertExpenseWhenCurrencyIsNotUsdKeepsOriginalValue() {
        let profileStorage = UserProfileStorageSpy(
            profile: .init(
                userId: "user-1",
                email: "user@example.com",
                name: "Test User",
                currency: "KZT",
                language: "ru",
                currencyRate: 2.0
            )
        )
        let sut = UserCurrencyConversionService(userProfileStorageService: profileStorage)

        let converted = sut.convertExpense(
            amount: 7.4,
            currency: "EUR"
        )

        XCTAssertEqual(converted.amount, 7.4)
        XCTAssertEqual(converted.currency, "EUR")
    }
}

private final class UserProfileStorageSpy: UserProfileStorageServiceProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var profile: UserProfileDefaults?

    init(profile: UserProfileDefaults?) {
        self.profile = profile
    }

    func saveProfile(_ profile: UserProfileDefaults) {
        lock.lock()
        self.profile = profile
        lock.unlock()
    }

    func loadProfile() -> UserProfileDefaults? {
        lock.lock()
        let value = profile
        lock.unlock()
        return value
    }

    func clearProfile() {
        lock.lock()
        profile = nil
        lock.unlock()
    }
}
