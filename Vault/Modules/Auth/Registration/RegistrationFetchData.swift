// Created by Egor Shkarin 16.03.2026

import Foundation

struct RegistrationFetchData: Sendable {
    let loadingState: LoadingStatus
    let step: RegistrationStep

    let email: String
    let password: String
    let confirmPassword: String
    let name: String
    let searchQuery: String
    let selectedCurrencyCode: String?
    let preferredLanguage: String

    let popularCurrencies: [RegistrationCurrency]
    let otherCurrencies: [RegistrationCurrency]

    let emailErrorMessage: String?
    let passwordErrorMessage: String?
    let confirmPasswordErrorMessage: String?
    let nameErrorMessage: String?
    let currencyErrorMessage: String?

    init(
        loadingState: LoadingStatus = .idle,
        step: RegistrationStep = .account,
        email: String = "",
        password: String = "",
        confirmPassword: String = "",
        name: String = "",
        searchQuery: String = "",
        selectedCurrencyCode: String? = nil,
        preferredLanguage: String = "",
        popularCurrencies: [RegistrationCurrency] = [],
        otherCurrencies: [RegistrationCurrency] = [],
        emailErrorMessage: String? = nil,
        passwordErrorMessage: String? = nil,
        confirmPasswordErrorMessage: String? = nil,
        nameErrorMessage: String? = nil,
        currencyErrorMessage: String? = nil
    ) {
        self.loadingState = loadingState
        self.step = step
        self.email = email
        self.password = password
        self.confirmPassword = confirmPassword
        self.name = name
        self.searchQuery = searchQuery
        self.selectedCurrencyCode = selectedCurrencyCode
        self.preferredLanguage = preferredLanguage
        self.popularCurrencies = popularCurrencies
        self.otherCurrencies = otherCurrencies
        self.emailErrorMessage = emailErrorMessage
        self.passwordErrorMessage = passwordErrorMessage
        self.confirmPasswordErrorMessage = confirmPasswordErrorMessage
        self.nameErrorMessage = nameErrorMessage
        self.currencyErrorMessage = currencyErrorMessage
    }
}
