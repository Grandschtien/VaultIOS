import Foundation

enum VaultWidgetValueFormatter {
    static func string(
        amount: Double?,
        currency: String?,
        locale: Locale = .current,
        fallback: String = "$0.00"
    ) -> String {
        guard let amount,
              let currency else {
            return fallback
        }

        return string(
            amount: amount,
            currencyCode: currency,
            locale: locale,
            fallback: fallback
        )
    }

    static func string(
        amount: Double,
        currencyCode: String,
        locale: Locale = .current,
        fallback: String? = nil
    ) -> String {
        let normalizedCurrencyCode = normalizedCurrencyCode(currencyCode)
        let resolvedFallback = fallback ?? "\(normalizedCurrencyCode) \(amount)"

        guard !normalizedCurrencyCode.isEmpty else {
            return resolvedFallback
        }

        return formatter(
            currencyCode: normalizedCurrencyCode,
            locale: locale
        ).string(from: NSNumber(value: amount)) ?? resolvedFallback
    }

    static func currencySymbol(
        for currencyCode: String,
        locale: Locale = .current,
        fallback: String? = nil
    ) -> String {
        let normalizedCurrencyCode = normalizedCurrencyCode(currencyCode)
        let resolvedFallback = fallback ?? normalizedCurrencyCode

        guard !normalizedCurrencyCode.isEmpty else {
            return resolvedFallback
        }

        return formatter(
            currencyCode: normalizedCurrencyCode,
            locale: locale
        ).currencySymbol ?? resolvedFallback
    }

    static func normalizedCurrencyCode(_ currencyCode: String?) -> String {
        guard let currencyCode else {
            return ""
        }

        return currencyCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }

    private static func formatter(
        currencyCode: String,
        locale: Locale
    ) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
}
