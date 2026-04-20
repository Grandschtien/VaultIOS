// Created by Egor Shkarin 16.03.2026

import Foundation
@preconcurrency import NetworkClient

protocol RegistrationBusinessLogic: Sendable {
    func fetchData() async
    func handleFlowDidExit() async
}

protocol RegistrationHandler: AnyObject, Sendable {
    func handleEmailDidChange(_ email: String) async
    func handlePasswordDidChange(_ password: String) async
    func handleConfirmPasswordDidChange(_ confirmPassword: String) async
    func handleNameDidChange(_ name: String) async
    func handleSearchQueryDidChange(_ searchQuery: String) async
    func handleSelectCurrency(_ currencyCode: String) async
    func handleTapPrimaryButton() async
    func handleTapSecondaryButton() async
}

actor RegistrationInteractor: RegistrationBusinessLogic {
    private let networkClient: AsyncNetworkClient
    private let presenter: RegistrationPresentationLogic
    private let router: RegistrationRoutingLogic
    private let tokenStorageService: TokenStorageServiceProtocol
    private let userProfileStorageService: UserProfileStorageServiceProtocol
    private let registrationStorage: RegistrationStorageProtocol
    private let currencyProvider: RegistrationCurrencyProviding
    private let localeProvider: RegistrationLocaleProviding
    private let subscriptionInitializer: SubscriptionInitializerLogic

    private let popularCurrencyCodes: [String] = ["USD", "RUB", "KZT"]

    private var step: RegistrationStep = .account
    private var loadingState: LoadingStatus = .idle

    private var email: String = ""
    private var password: String = ""
    private var confirmPassword: String = ""
    private var name: String = ""
    private var searchQuery: String = ""
    private var selectedCurrencyCode: String?
    private var preferredLanguage: String = ""

    private var emailErrorMessage: String?
    private var passwordErrorMessage: String?
    private var confirmPasswordErrorMessage: String?
    private var nameErrorMessage: String?
    private var currencyErrorMessage: String?

    private var allCurrencies: [RegistrationCurrency] = []

    init(
        networkClient: AsyncNetworkClient,
        presenter: RegistrationPresentationLogic,
        router: RegistrationRoutingLogic,
        tokenStorageService: TokenStorageServiceProtocol,
        userProfileStorageService: UserProfileStorageServiceProtocol,
        registrationStorage: RegistrationStorageProtocol,
        subscriptionInitializer: SubscriptionInitializerLogic,
        currencyProvider: RegistrationCurrencyProviding = RegistrationCurrencyProvider(),
        localeProvider: RegistrationLocaleProviding = RegistrationLocaleProvider()
    ) {
        self.networkClient = networkClient
        self.presenter = presenter
        self.router = router
        self.tokenStorageService = tokenStorageService
        self.userProfileStorageService = userProfileStorageService
        self.registrationStorage = registrationStorage
        self.subscriptionInitializer = subscriptionInitializer
        self.currencyProvider = currencyProvider
        self.localeProvider = localeProvider
    }

    func fetchData() async {
        allCurrencies = currencyProvider.fiatCurrencies()

        let draft = await registrationStorage.loadDraft()
        email = draft.email
        password = draft.password
        confirmPassword = draft.confirmPassword
        name = draft.name
        selectedCurrencyCode = draft.currencyCode

        preferredLanguage = localeProvider.preferredLanguageIdentifier

        if selectedCurrencyCode == nil {
            let preferredCurrencyCode = localeProvider.preferredCurrencyCode
            if allCurrencies.contains(where: { $0.code == preferredCurrencyCode }) {
                selectedCurrencyCode = preferredCurrencyCode
            } else {
                selectedCurrencyCode = "USD"
            }
        }

        step = .account
        loadingState = .idle
        clearValidationErrors()

        await presentFetchedData()
    }

    func handleFlowDidExit() async {
        await registrationStorage.clear()
    }
}

private extension RegistrationInteractor {
    func presentFetchedData() async {
        let sections = makeCurrencySections()

        await presenter.presentFetchedData(
            RegistrationFetchData(
                loadingState: loadingState,
                step: step,
                email: email,
                password: password,
                confirmPassword: confirmPassword,
                name: name,
                searchQuery: searchQuery,
                selectedCurrencyCode: selectedCurrencyCode,
                preferredLanguage: preferredLanguage,
                popularCurrencies: sections.popular,
                otherCurrencies: sections.other,
                emailErrorMessage: emailErrorMessage,
                passwordErrorMessage: passwordErrorMessage,
                confirmPasswordErrorMessage: confirmPasswordErrorMessage,
                nameErrorMessage: nameErrorMessage,
                currencyErrorMessage: currencyErrorMessage
            )
        )
    }

    func makeCurrencySections() -> (popular: [RegistrationCurrency], other: [RegistrationCurrency]) {
        let normalizedQuery = searchQuery
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let filtered: [RegistrationCurrency]
        if normalizedQuery.isEmpty {
            filtered = allCurrencies
        } else {
            filtered = allCurrencies.filter {
                $0.code.lowercased().contains(normalizedQuery)
                    || $0.title.lowercased().contains(normalizedQuery)
            }
        }

        let popular = popularCurrencyCodes.compactMap { code in
            filtered.first(where: { $0.code == code })
        }

        let popularCodes = Set(popular.map(\.code))
        let other = filtered.filter { !popularCodes.contains($0.code) }

        return (popular: popular, other: other)
    }

    func persistDraft() async {
        await registrationStorage.saveDraft(
            RegistrationDraft(
                email: email,
                password: password,
                confirmPassword: confirmPassword,
                name: name,
                currencyCode: selectedCurrencyCode
            )
        )
    }

    func clearValidationErrors() {
        emailErrorMessage = nil
        passwordErrorMessage = nil
        confirmPasswordErrorMessage = nil
        nameErrorMessage = nil
        currencyErrorMessage = nil
    }

    func clearAccountStepErrors() {
        emailErrorMessage = nil
        passwordErrorMessage = nil
        confirmPasswordErrorMessage = nil
    }

    func validateAccountStep() -> Bool {
        clearAccountStepErrors()

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedConfirmPassword = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        if normalizedEmail.isEmpty {
            emailErrorMessage = L10n.commonFillField
        } else if !normalizedEmail.isValidEmail {
            emailErrorMessage = L10n.registrationErrorInvalidEmail
        }

        if normalizedPassword.isEmpty {
            passwordErrorMessage = L10n.commonFillField
        }

        if normalizedConfirmPassword.isEmpty {
            confirmPasswordErrorMessage = L10n.commonFillField
        } else if normalizedPassword != normalizedConfirmPassword {
            confirmPasswordErrorMessage = L10n.registrationErrorPasswordMismatch
        }

        return emailErrorMessage == nil
            && passwordErrorMessage == nil
            && confirmPasswordErrorMessage == nil
    }

    func validateNameStep() -> Bool {
        nameErrorMessage = nil

        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedName.isEmpty {
            nameErrorMessage = L10n.commonFillField
            return false
        }

        return true
    }

    func validateCurrencyStep() -> Bool {
        currencyErrorMessage = nil

        guard let selectedCurrencyCode,
              allCurrencies.contains(where: { $0.code == selectedCurrencyCode })
        else {
            currencyErrorMessage = L10n.registrationErrorSelectCurrency
            return false
        }

        return true
    }

    func register() async {
        do {
            loadingState = .loading
            await presentFetchedData()

            let response = try await networkClient.request(
                AuthAPI.register(
                    RegisterRequestDTO(
                        provider: "password",
                        email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                        password: password.trimmingCharacters(in: .whitespacesAndNewlines),
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        currency: selectedCurrencyCode ?? "USD",
                        preferredLanguage: preferredLanguage
                    )
                ),
                responseType: LoginResponseDTO.self
            )

            tokenStorageService.setToken(
                AuthTokenDTO(
                    accessToken: response.accessToken,
                    refreshToken: response.refreshToken,
                    tokenType: response.tokenType,
                    expiresIn: response.expiresIn
                )
            )
            userProfileStorageService.saveProfile(
                UserProfileDefaults(user: response.user)
            )

            loadingState = .loaded
            await subscriptionInitializer.setUserId(response.user.id)
            await registrationStorage.clear()
            await presentFetchedData()
            await router.openMainFlow()
        } catch {
            loadingState = .failed(.undelinedError(description: error.localizedDescription))
            await presentFetchedData()
            await router.presentError(with: error.localizedDescription)
        }
    }
}

extension RegistrationInteractor: RegistrationHandler {
    func handleEmailDidChange(_ email: String) async {
        self.email = email
        emailErrorMessage = nil
        await persistDraft()
    }

    func handlePasswordDidChange(_ password: String) async {
        self.password = password
        passwordErrorMessage = nil
        await persistDraft()
    }

    func handleConfirmPasswordDidChange(_ confirmPassword: String) async {
        self.confirmPassword = confirmPassword
        confirmPasswordErrorMessage = nil
        await persistDraft()
    }

    func handleNameDidChange(_ name: String) async {
        self.name = name
        nameErrorMessage = nil
        await persistDraft()
    }

    func handleSearchQueryDidChange(_ searchQuery: String) async {
        self.searchQuery = searchQuery
        await presentFetchedData()
    }

    func handleSelectCurrency(_ currencyCode: String) async {
        selectedCurrencyCode = currencyCode
        currencyErrorMessage = nil
        await persistDraft()
        await presentFetchedData()
    }

    func handleTapPrimaryButton() async {
        if case .loading = loadingState {
            return
        }

        switch step {
        case .account:
            guard validateAccountStep() else {
                await presentFetchedData()
                return
            }

            step = .name
            loadingState = .idle
            await persistDraft()
            await presentFetchedData()

        case .name:
            guard validateNameStep() else {
                await presentFetchedData()
                return
            }

            step = .currency
            loadingState = .idle
            await persistDraft()
            await presentFetchedData()

        case .currency:
            guard validateCurrencyStep() else {
                await presentFetchedData()
                return
            }

            await register()
        }
    }

    func handleTapSecondaryButton() async {
        if case .loading = loadingState {
            return
        }

        switch step {
        case .account:
            return
        case .name:
            step = .account
        case .currency:
            step = .name
        }

        loadingState = .idle
        clearValidationErrors()
        await presentFetchedData()
    }
}
