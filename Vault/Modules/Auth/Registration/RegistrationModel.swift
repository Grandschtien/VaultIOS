// Created by Egor Shkarin on 16.03.2026

import Foundation
import CoreGraphics

enum RegistrationStep: Int, CaseIterable, Sendable {
    case account
    case name
    case currency

    var number: Int {
        rawValue + 1
    }

    var total: Int {
        Self.allCases.count
    }

    var progress: CGFloat {
        CGFloat(number) / CGFloat(total)
    }
}

struct RegistrationCurrency: Equatable, Sendable {
    let code: String
    let title: String
}

protocol RegistrationCurrencyProviding: Sendable {
    func fiatCurrencies() -> [RegistrationCurrency]
}

final class RegistrationCurrencyProvider: RegistrationCurrencyProviding, @unchecked Sendable {
    func fiatCurrencies() -> [RegistrationCurrency] {
        Locale.commonISOCurrencyCodes
            .map { $0.uppercased() }
            .map { code in
                RegistrationCurrency(
                    code: code,
                    title: Locale.current.localizedString(forCurrencyCode: code) ?? code
                )
            }
            .sorted {
                if $0.title == $1.title {
                    return $0.code < $1.code
                }

                return $0.title < $1.title
            }
    }
}

protocol RegistrationLocaleProviding: Sendable {
    var preferredLanguageIdentifier: String { get }
    var preferredCurrencyCode: String { get }
}

struct RegistrationLocaleProvider: RegistrationLocaleProviding {
    var preferredLanguageIdentifier: String {
        Locale.preferredLanguages.first ?? Locale.current.identifier
    }

    var preferredCurrencyCode: String {
        if let languageCurrencyCode = Locale(
            identifier: preferredLanguageIdentifier
        ).currency?.identifier {
            return languageCurrencyCode.uppercased()
        }

        if let currentCurrencyCode = Locale.current.currency?.identifier {
            return currentCurrencyCode.uppercased()
        }

        return "USD"
    }
}
