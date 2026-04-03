// Created by Egor Shkarin 29.03.2026

import Foundation
import UIKit
internal import Combine

@MainActor
protocol ProfilePresentationLogic: Sendable {
    func presentFetchedData(_ data: ProfileFetchData)
}

final class ProfilePresenter: ProfilePresentationLogic {

    @Published
    private(set) var viewModel: ProfileViewModel

    weak var handler: ProfileHandler?

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
    }

    func presentFetchedData(_ data: ProfileFetchData) {
        let selectedCurrencyCode = resolvedSelectedCurrencyCode(from: data)
        let hasUnsavedCurrencyChange = hasUnsavedCurrencyChange(
            profile: data.profile,
            selectedCurrencyCode: selectedCurrencyCode
        )
        let content = makeContent(from: data)

        viewModel = ProfileViewModel(
            navigationTitle: .init(
                text: data.navigationTitle,
                font: Typography.typographySemibold20,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .left
            ),
            isBackButtonHidden: hasUnsavedCurrencyChange,
            saveCurrencyButton: hasUnsavedCurrencyChange
                ? .init(
                    tapCommand: Command { [weak handler] in
                        await handler?.handleTapSaveCurrency()
                    },
                    isEnabled: !data.isSavingCurrency
                )
                : nil,
            state: makeState(
                from: data.loadingState,
                content: content
            )
        )
    }
}

private extension ProfilePresenter {
    func makeState(
        from loadingState: LoadingStatus,
        content: ProfileViewModel.Content
    ) -> ProfileViewModel.State {
        switch loadingState {
        case .loaded:
            return .loaded(content)
        case .failed:
            return .error(makeErrorViewModel())
        case .idle, .loading:
            return .loading(content)
        }
    }

    func makeContent(from data: ProfileFetchData) -> ProfileViewModel.Content {
        let profileName = data.profile?.name ?? ""
        let tier = displayTier(from: data.profile?.tier ?? "")
        let selectedCurrencyCode = resolvedSelectedCurrencyCode(from: data)

        return ProfileViewModel.Content(
            avatar: .init(
                initials: .init(
                    text: initials(from: profileName),
                    font: Typography.typographyBold20,
                    textColor: Asset.Colors.textAndIconPrimary.color,
                    alignment: .center
                ),
                backgroundColor: Asset.Colors.interactiveInputBackground.color
            ),
            name: .init(
                text: profileName,
                font: Typography.typographyBold28,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .center
            ),
            membership: .init(
                text: membershipTitle(from: tier),
                font: Typography.typographyRegular16,
                textColor: Asset.Colors.textAndIconPlaceseholder.color,
                alignment: .center
            ),
            plan: .init(
                icon: Asset.Icons.star.image,
                title: .init(
                    text: tier.isEmpty ? L10n.profilePlan : tier,
                    font: Typography.typographyBold18,
                    textColor: Asset.Colors.textAndIconPrimaryInverted.color,
                    alignment: .left
                ),
                subtitle: .init(
                    text: validUntilTitle(from: data.profile?.tierValidUntil),
                    font: Typography.typographyRegular14,
                    textColor: Asset.Colors.textAndIconPrimaryInverted.color.withAlphaComponent(0.75),
                    alignment: .left
                )
            ),
            generalSectionTitle: .init(
                text: L10n.profileGeneral,
                font: Typography.typographySemibold12,
                textColor: Asset.Colors.textAndIconPlaceseholder.color,
                alignment: .left
            ),
            rows: makeRows(
                from: data.profile,
                selectedCurrencyCode: selectedCurrencyCode
            ),
            logoutButton: .init(
                title: L10n.profileLogout,
                titleColor: Asset.Colors.errorColor.color,
                backgroundColor: .clear,
                font: Typography.typographyMedium16,
                isEnabled: !data.isLoggingOut,
                isLoading: data.isLoggingOut,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapLogout()
                },
                leftIcon: Asset.Icons.logout.image,
                iconTintColor: Asset.Colors.errorColor.color
            ),
            version: .init(
                text: L10n.profileVersion(data.appVersion, data.appBuild),
                font: Typography.typographyRegular12,
                textColor: Asset.Colors.textAndIconPlaceseholder.color,
                alignment: .center
            ),
            isSavingCurrency: data.isSavingCurrency
        )
    }

    func makeRows(
        from profile: ProfileResponseDTO?,
        selectedCurrencyCode: String
    ) -> [ProfileViewModel.GeneralRow] {
        [
            .init(
                icon: Asset.Icons.currency.image,
                iconBackgroundColor: Asset.Colors.interactiveInputBackground.color,
                title: .init(
                    text: L10n.profileCurrency,
                    font: Typography.typographyMedium16,
                    textColor: Asset.Colors.textAndIconPrimary.color,
                    alignment: .left
                ),
                subtitle: .init(
                    text: currencyTitle(
                        from: selectedCurrencyCode.isEmpty
                            ? (profile?.currency ?? "")
                            : selectedCurrencyCode
                    ),
                    font: Typography.typographyRegular12,
                    textColor: Asset.Colors.textAndIconPlaceseholder.color,
                    alignment: .left
                ),
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapCurrency()
                }
            ),
            .init(
                icon: Asset.Icons.earth.image,
                iconBackgroundColor: Asset.Colors.interactiveInputBackground.color,
                title: .init(
                    text: L10n.profileLanguage,
                    font: Typography.typographyMedium16,
                    textColor: Asset.Colors.textAndIconPrimary.color,
                    alignment: .left
                ),
                subtitle: .init(
                    text: languageTitle(from: profile?.preferredLanguage ?? ""),
                    font: Typography.typographyRegular12,
                    textColor: Asset.Colors.textAndIconPlaceseholder.color,
                    alignment: .left
                )
            )
        ]
    }

    func makeErrorViewModel() -> FullScreenCommonErrorView.ViewModel {
        FullScreenCommonErrorView.ViewModel(
            title: .init(
                text: L10n.profileError,
                font: Typography.typographyBold14,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .center
            ),
            tapCommand: Command { [weak handler] in
                await handler?.handleTapRetry()
            }
        )
    }

    func initials(from name: String) -> String {
        let words = name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }

        if words.isEmpty {
            return "?"
        }

        return String(words).uppercased()
    }

    func displayTier(from rawTier: String) -> String {
        let trimmed = rawTier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ""
        }

        return trimmed
            .replacingOccurrences(of: "_", with: " ")
            .lowercased()
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    func membershipTitle(from tier: String) -> String {
        guard !tier.isEmpty else {
            return L10n.profileMember
        }

        return L10n.profileMemberStatus(tier)
    }

    func validUntilTitle(from date: Date?) -> String {
        guard let date else {
            return L10n.profileValidUntilUnknown
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd.mm.yyyy"

        return L10n.profileValidUntil(formatter.string(from: date))
    }

    func currencyTitle(from code: String) -> String {
        let normalized = code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard !normalized.isEmpty else {
            return "-"
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = normalized
        formatter.locale = Locale.current
        let symbol = formatter.currencySymbol ?? normalized

        return "\(normalized) (\(symbol))"
    }

    func languageTitle(from identifier: String) -> String {
        let normalized = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return "-"
        }

        let locale = Locale(identifier: normalized)
        guard let languageCode = locale.language.languageCode?.identifier else {
            return normalized
        }

        let language = Locale.current.localizedString(forLanguageCode: languageCode) ?? languageCode

        return language.capitalized
    }

    func normalizedCurrencyCode(_ code: String?) -> String {
        guard let code else {
            return ""
        }

        return code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }

    func resolvedSelectedCurrencyCode(from data: ProfileFetchData) -> String {
        let selectedCurrencyCode = normalizedCurrencyCode(data.selectedCurrencyCode)
        if !selectedCurrencyCode.isEmpty {
            return selectedCurrencyCode
        }

        return normalizedCurrencyCode(data.profile?.currency)
    }

    func hasUnsavedCurrencyChange(
        profile: ProfileResponseDTO?,
        selectedCurrencyCode: String
    ) -> Bool {
        let profileCurrencyCode = normalizedCurrencyCode(profile?.currency)

        guard !profileCurrencyCode.isEmpty else {
            return false
        }

        return profileCurrencyCode != selectedCurrencyCode
    }
}
