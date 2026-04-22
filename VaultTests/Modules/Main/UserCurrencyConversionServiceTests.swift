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
            currency: "USD",
            originalAmount: nil,
            originalCurrency: nil
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
            currency: "EUR",
            originalAmount: nil,
            originalCurrency: nil
        )

        XCTAssertEqual(converted.amount, 7.4)
        XCTAssertEqual(converted.currency, "EUR")
    }

    func testConvertExpenseWhenOriginalCurrencyMatchesPreferredCurrencyReturnsOriginalValue() {
        let profileStorage = UserProfileStorageSpy(
            profile: .init(
                userId: "user-1",
                email: "user@example.com",
                name: "Test User",
                currency: "RUB",
                language: "ru",
                currencyRate: 76.34
            )
        )
        let sut = UserCurrencyConversionService(userProfileStorageService: profileStorage)

        let converted = sut.convertExpense(
            amount: 2.62,
            currency: "USD",
            originalAmount: 200,
            originalCurrency: "RUB"
        )

        XCTAssertEqual(converted.amount, 200)
        XCTAssertEqual(converted.currency, "RUB")
    }

    func testConvertExpenseWhenOriginalCurrencyMatchesPreferredCurrencyAfterNormalizationReturnsOriginalValue() {
        let profileStorage = UserProfileStorageSpy(
            profile: .init(
                userId: "user-1",
                email: "user@example.com",
                name: "Test User",
                currency: " kzt ",
                language: "ru",
                currencyRate: 2.0
            )
        )
        let sut = UserCurrencyConversionService(userProfileStorageService: profileStorage)

        let converted = sut.convertExpense(
            amount: 7.4,
            currency: "USD",
            originalAmount: 1500,
            originalCurrency: " KZT "
        )

        XCTAssertEqual(converted.amount, 1500)
        XCTAssertEqual(converted.currency, "KZT")
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
