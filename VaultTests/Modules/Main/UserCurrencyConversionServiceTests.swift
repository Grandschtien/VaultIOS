import XCTest
@testable import Vylok

final class UserCurrencyConversionServiceTests: XCTestCase {
    func testConvertUsdAmountWhenProfileHasRateConvertsIntoPreferredCurrency() {
        let profileStorage = UserProfileStorageServiceProtocolMock()
        profileStorage.loadProfileReturnValue = UserProfileDefaults(
            userId: "user-1",
            email: "user@example.com",
            name: "Test User",
            currency: "EUR",
            language: "en-US",
            currencyRate: 2.0
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
            userProfileStorageService: UserProfileStorageServiceProtocolMock()
        )

        let converted = sut.convertUsdAmount(10)

        XCTAssertEqual(converted.amount, 10)
        XCTAssertEqual(converted.currency, "USD")
    }
}

extension UserCurrencyConversionServiceTests {
    func testConvertExpenseWhenCurrencyIsUsdConvertsToPreferredCurrency() {
        let profileStorage = UserProfileStorageServiceProtocolMock()
        profileStorage.loadProfileReturnValue = UserProfileDefaults(
            userId: "user-1",
            email: "user@example.com",
            name: "Test User",
            currency: "KZT",
            language: "ru",
            currencyRate: 2.0
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
        let profileStorage = UserProfileStorageServiceProtocolMock()
        profileStorage.loadProfileReturnValue = UserProfileDefaults(
            userId: "user-1",
            email: "user@example.com",
            name: "Test User",
            currency: "KZT",
            language: "ru",
            currencyRate: 2.0
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
        let profileStorage = UserProfileStorageServiceProtocolMock()
        profileStorage.loadProfileReturnValue = UserProfileDefaults(
            userId: "user-1",
            email: "user@example.com",
            name: "Test User",
            currency: "RUB",
            language: "ru",
            currencyRate: 76.34
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
        let profileStorage = UserProfileStorageServiceProtocolMock()
        profileStorage.loadProfileReturnValue = UserProfileDefaults(
            userId: "user-1",
            email: "user@example.com",
            name: "Test User",
            currency: " kzt ",
            language: "ru",
            currencyRate: 2.0
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
