// Created by Egor Shkarin 29.03.2026

import Foundation

protocol ProfileBusinessLogic: Sendable {
    func fetchData() async
}

protocol ProfileHandler: AnyObject, Sendable {
    func handleTapRetry() async
    func handleTapLogout() async
    func handleTapCurrency() async
    func handleTapSaveCurrency() async
    func handleTapSubscription() async
}

actor ProfileInteractor: ProfileBusinessLogic {
    private let presenter: ProfilePresentationLogic
    private let router: ProfileRoutingLogic
    private let profileService: ProfileContractServicing
    private let currencyRateService: MainCurrencyRateContractServicing
    private let userProfileStorageService: UserProfileStorageServiceProtocol
    private let authSessionService: AuthSessionServiceProtocol
    private let subscriptionAccessService: SubscriptionAccessServicing
    private let analytics: ProfileAnalyticsTracking?

    private var loadingState: LoadingStatus = .idle
    private var isSavingCurrency: Bool = false
    private var isLoggingOut: Bool = false
    private var hasTrackedScreenOpen: Bool = false
    private var profile: ProfileResponseDTO?
    private var subscription: SubscriptionAccessSnapshot?
    private var selectedCurrencyCode: String?

    init(
        presenter: ProfilePresentationLogic,
        router: ProfileRoutingLogic,
        profileService: ProfileContractServicing,
        currencyRateService: MainCurrencyRateContractServicing,
        userProfileStorageService: UserProfileStorageServiceProtocol,
        authSessionService: AuthSessionServiceProtocol,
        subscriptionAccessService: SubscriptionAccessServicing,
        analytics: ProfileAnalyticsTracking? = nil
    ) {
        self.presenter = presenter
        self.router = router
        self.profileService = profileService
        self.currencyRateService = currencyRateService
        self.userProfileStorageService = userProfileStorageService
        self.authSessionService = authSessionService
        self.subscriptionAccessService = subscriptionAccessService
        self.analytics = analytics
    }

    func fetchData() async {
        if !hasTrackedScreenOpen {
            analytics?.trackScreenOpen()
            hasTrackedScreenOpen = true
        }
        loadingState = .loading
        isSavingCurrency = false
        isLoggingOut = false
        profile = nil
        subscription = nil
        let cachedCurrency = normalizedCurrencyCode(
            userProfileStorageService.loadProfile()?.currency
        )
        selectedCurrencyCode = cachedCurrency.isEmpty ? nil : cachedCurrency
        await presentFetchedData()

        do {
            async let fetchedProfile = profileService.getProfile()
            async let fetchedSubscription = subscriptionAccessService.refreshCurrentSubscriptionSnapshot()

            profile = try await fetchedProfile
            subscription = await fetchedSubscription
            loadingState = .loaded
            selectedCurrencyCode = normalizedCurrencyCode(profile?.currency)
            await presentFetchedData()
            analytics?.trackProfileSuccess()
        } catch {
            analytics?.trackProfileFailure(error)
            loadingState = .failed(.undelinedError(description: error.localizedDescription))
            await presentFetchedData()
        }
    }
}

private extension ProfileInteractor {
    func presentFetchedData() async {
        await presenter.presentFetchedData(
            ProfileFetchData(
                loadingState: loadingState,
                profile: profile,
                subscription: subscription,
                selectedCurrencyCode: selectedCurrencyCode,
                isSavingCurrency: isSavingCurrency,
                isLoggingOut: isLoggingOut,
                appVersion: appVersion(),
                appBuild: appBuild()
            )
        )
    }

    func appVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    func appBuild() -> String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    func normalizedCurrencyCode(_ code: String?) -> String {
        guard let code else {
            return ""
        }

        return code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }

    func saveFailedMessage(from error: Error) -> String {
        if error is ProfileSaveError {
            return L10n.profileCurrencyUpdateFailed
        }

        let message = error.localizedDescription
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if message.isEmpty {
            return L10n.profileCurrencyUpdateFailed
        }

        return message
    }

    func logoutFailedMessage(from error: Error) -> String {
        let message = error.localizedDescription
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if message.isEmpty {
            return L10n.profileError
        }

        return message
    }

    func persistLocalProfile(
        with profile: ProfileResponseDTO,
        rateToUsd: Double
    ) throws {
        let currentLocalProfile = userProfileStorageService.loadProfile()
        let email = profile.email ?? currentLocalProfile?.email

        guard let email, !email.isEmpty else {
            throw ProfileSaveError.missingEmail
        }

        userProfileStorageService.saveProfile(
            UserProfileDefaults(
                userId: profile.id,
                email: email,
                name: profile.name,
                currency: normalizedCurrencyCode(profile.currency),
                language: profile.preferredLanguage,
                currencyRate: rateToUsd,
                currencyRateUpdatedAt: Date(),
                cachedSubscription: currentLocalProfile?.cachedSubscription
            )
        )
    }
}

extension ProfileInteractor: ProfileHandler {
    func handleTapRetry() async {
        await fetchData()
    }

    func handleTapLogout() async {
        guard !isLoggingOut else {
            return
        }

        analytics?.trackLogoutScreenOpen()
        await router.openConfirmation(context: logoutConfirmationContext())
    }

    func handleTapCurrency() async {
        let currentCurrencyCode = normalizedCurrencyCode(selectedCurrencyCode)
        guard !currentCurrencyCode.isEmpty else {
            return
        }

        analytics?.trackCurrencyScreenOpen()
        await router.openCurrencySelection(
            currentCurrencyCode: currentCurrencyCode,
            output: self
        )
    }

    func handleTapSaveCurrency() async {
        guard let currentProfile = profile else {
            return
        }

        let previousCurrencyCode = normalizedCurrencyCode(currentProfile.currency)
        let updatedCurrencyCode = normalizedCurrencyCode(selectedCurrencyCode)
        let previousRateToUsd = userProfileStorageService.loadProfile()?.currencyRate

        guard !updatedCurrencyCode.isEmpty,
              updatedCurrencyCode != previousCurrencyCode
        else {
            return
        }

        isSavingCurrency = true
        await presentFetchedData()

        do {
            let patchedProfile = try await profileService.updateProfile(
                .init(currency: updatedCurrencyCode)
            )

            do {
                let updatedRate = try await currencyRateService.getCurrencyRate(
                    currency: updatedCurrencyCode
                )

                try persistLocalProfile(
                    with: patchedProfile,
                    rateToUsd: updatedRate.rateToUsd
                )
                profile = patchedProfile
                selectedCurrencyCode = normalizedCurrencyCode(patchedProfile.currency)
                isSavingCurrency = false
                loadingState = .loaded
                await presentFetchedData()
                analytics?.trackCurrencySaveSuccess(
                    previousCurrencyCode: previousCurrencyCode,
                    updatedCurrencyCode: updatedCurrencyCode
                )
                NotificationCenter.default.post(
                    name: .profileCurrencyDidChange,
                    object: ProfileCurrencyDidChangePayload(
                        previousCurrencyCode: previousCurrencyCode,
                        previousRateToUsd: previousRateToUsd,
                        updatedCurrencyCode: updatedCurrencyCode,
                        updatedRateToUsd: updatedRate.rateToUsd
                    )
                )
            } catch {
                _ = try? await profileService.updateProfile(
                    .init(currency: previousCurrencyCode)
                )
                throw error
            }
        } catch {
            isSavingCurrency = false
            selectedCurrencyCode = previousCurrencyCode
            loadingState = .loaded
            await presentFetchedData()
            analytics?.trackCurrencySaveFailure(
                previousCurrencyCode: previousCurrencyCode,
                updatedCurrencyCode: updatedCurrencyCode,
                error: error
            )
            await router.presentError(with: saveFailedMessage(from: error))
        }
    }

    func handleTapSubscription() async {
        guard loadingState == .loaded else {
            return
        }

        let currentTier = subscription?.tier ?? .regular
        analytics?.trackPaywallOpen(currentTier: currentTier.rawValue)
        await router.openSubscription(
            currentTier: currentTier,
            output: self
        )
    }
}

extension ProfileInteractor: ProfileCurrencySelectionOutput {
    func handleDidSelectCurrency(_ currencyCode: String) async {
        selectedCurrencyCode = normalizedCurrencyCode(currencyCode)
        await presentFetchedData()
    }
}

private extension ProfileInteractor {
    func logoutConfirmationContext() -> CommonConfirmationContext {
        CommonConfirmationContext(
            title: L10n.profileLogoutConfirmationTitle,
            confirmButtonTitle: L10n.commonConfirm,
            cancelButtonTitle: L10n.commonCancel,
            confirmCommand: Command { [weak self] in
                await self?.performLogout()
            }
        )
    }

    func performLogout() async {
        guard !isLoggingOut else {
            return
        }

        isLoggingOut = true
        await presentFetchedData()

        do {
            try await authSessionService.logoutFromBackend()
            analytics?.trackLogoutSuccess()
        } catch {
            isLoggingOut = false
            await presentFetchedData()
            analytics?.trackLogoutFailure(error)
            await router.presentError(with: logoutFailedMessage(from: error))
        }
    }

    enum ProfileSaveError: Error {
        case missingEmail
    }
}

extension ProfileInteractor: SubscriptionOutput {
    func handleSubscriptionDidSync() async {
        await fetchData()
    }
}
