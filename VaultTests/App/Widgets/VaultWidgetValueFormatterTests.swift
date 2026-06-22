import XCTest
@testable import Vault

final class VaultWidgetValueFormatterTests: XCTestCase {
    func testStringReturnsFormattedCurrencyForNormalizedCode() {
        let result = VaultWidgetValueFormatter.string(
            amount: 2755,
            currencyCode: " usd ",
            locale: Locale(identifier: "en_US")
        )

        XCTAssertEqual(result, "$2,755.00")
    }

    func testStringReturnsFallbackWhenValueIsMissing() {
        let result = VaultWidgetValueFormatter.string(
            amount: nil,
            currency: nil,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertEqual(result, "$0.00")
    }

    func testCurrencySymbolReturnsResolvedSymbol() {
        let result = VaultWidgetValueFormatter.currencySymbol(
            for: " eur ",
            locale: Locale(identifier: "en_US"),
            fallback: "EUR"
        )

        XCTAssertEqual(result, "€")
    }
}
