// Created by Egor Shkarin on 29.03.2026

import Foundation

struct UserCurrencyAmount: Equatable, Sendable {
    let amount: Double
    let currency: String
}

protocol UserCurrencyConverting: Sendable {
    func convertUsdAmount(_ amount: Double) -> UserCurrencyAmount
    func convertExpense(
        amount: Double,
        currency: String,
        originalAmount: Double?,
        originalCurrency: String?
    ) -> UserCurrencyAmount
}

final class UserCurrencyConversionService: UserCurrencyConverting, @unchecked Sendable {
    private enum Constants {
        static let defaultCurrency = "USD"
    }

    private let userProfileStorageService: UserProfileStorageServiceProtocol

    init(userProfileStorageService: UserProfileStorageServiceProtocol) {
        self.userProfileStorageService = userProfileStorageService
    }

    func convertUsdAmount(_ amount: Double) -> UserCurrencyAmount {
        let preferredCurrency = preferredCurrencyCode()

        guard isSameCurrency(preferredCurrency, Constants.defaultCurrency) == false else {
            return .init(amount: amount, currency: Constants.defaultCurrency)
        }

        guard let rateToUsd = userProfileStorageService.loadProfile()?.currencyRate,
              rateToUsd > .zero else {
            return .init(amount: amount, currency: preferredCurrency)
        }

        return .init(
            amount: amount / rateToUsd,
            currency: preferredCurrency
        )
    }

    func convertExpense(
        amount: Double,
        currency: String,
        originalAmount: Double?,
        originalCurrency: String?
    ) -> UserCurrencyAmount {
        let preferredCurrency = preferredCurrencyCode()

        if let originalAmount,
           let originalCurrency,
           isSameCurrency(originalCurrency, preferredCurrency) {
            return .init(amount: originalAmount, currency: preferredCurrency)
        }

        if isSameCurrency(currency, Constants.defaultCurrency) {
            return convertUsdAmount(amount)
        }

        if isSameCurrency(currency, preferredCurrency) {
            return .init(amount: amount, currency: preferredCurrency)
        }

        return .init(amount: amount, currency: currency)
    }
}

private extension UserCurrencyConversionService {
    func preferredCurrencyCode() -> String {
        userProfileStorageService.loadProfile()?.currency ?? Constants.defaultCurrency
    }

    func isSameCurrency(_ left: String, _ right: String) -> Bool {
        left.compare(right, options: [.caseInsensitive]) == .orderedSame
    }
}
