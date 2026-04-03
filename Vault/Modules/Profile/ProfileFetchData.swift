// Created by Egor Shkarin 29.03.2026

import Foundation

struct ProfileFetchData: Sendable {
    let navigationTitle: String
    let loadingState: LoadingStatus
    let profile: ProfileResponseDTO?
    let selectedCurrencyCode: String?
    let isSavingCurrency: Bool
    let isLoggingOut: Bool
    let appVersion: String
    let appBuild: String

    init(
        navigationTitle: String = L10n.profileSettingsTitle,
        loadingState: LoadingStatus = .idle,
        profile: ProfileResponseDTO? = nil,
        selectedCurrencyCode: String? = nil,
        isSavingCurrency: Bool = false,
        isLoggingOut: Bool = false,
        appVersion: String = "",
        appBuild: String = ""
    ) {
        self.navigationTitle = navigationTitle
        self.loadingState = loadingState
        self.profile = profile
        self.selectedCurrencyCode = selectedCurrencyCode
        self.isSavingCurrency = isSavingCurrency
        self.isLoggingOut = isLoggingOut
        self.appVersion = appVersion
        self.appBuild = appBuild
    }
}
