// Created by Egor Shkarin 16.03.2026

import Foundation
import UIKit
internal import Combine

@MainActor
protocol RegistrationPresentationLogic: Sendable {
    func presentFetchedData(_ data: RegistrationFetchData)
}

final class RegistrationPresenter: RegistrationPresentationLogic, ImageProviding {
    @Published
    private(set) var viewModel: RegistrationViewModel

    weak var handler: RegistrationHandler?

    init(viewModel: RegistrationViewModel) {
        self.viewModel = viewModel
    }

    func presentFetchedData(_ data: RegistrationFetchData) {
        let isLoading: Bool
        switch data.loadingState {
        case .loading:
            isLoading = true
        case .idle, .loaded, .failed:
            isLoading = false
        }

        viewModel = RegistrationViewModel(
            navigationTitle: .init(
                text: L10n.emailAddress,
                font: Typography.typographyMedium20,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .left
            ),
            stepLabel: .init(
                text: L10n.stepNumber(data.step.number, data.step.total),
                font: Typography.typographyBold12,
                textColor: Asset.Colors.textAndIconPlaceseholder.color,
                alignment: .left
            ),
            progress: .init(value: data.step.progress),
            content: makeContentViewModel(from: data),
            primaryButton: .init(
                title: data.step == .currency ? L10n.getStarted : L10n.next,
                titleColor: Asset.Colors.textAndIconPrimaryInverted.color,
                backgroundColor: Asset.Colors.interactiveElemetsPrimary.color,
                font: Typography.typographyBold18,
                isEnabled: !isLoading,
                isLoading: isLoading,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapPrimaryButton()
                },
                rightIcon: data.step == .currency ? nil : Asset.Icons.arrowRight.image,
                iconTintColor: Asset.Colors.textAndIconPrimaryInverted.color,
                height: 64,
                cornerRadius: 32
            ),
            secondaryButton: .init(
                title: L10n.registrationBack,
                titleColor: Asset.Colors.textAndIconPrimary.color,
                backgroundColor: Asset.Colors.interactiveInputBackground.color,
                font: Typography.typographySemibold16,
                isEnabled: !isLoading,
                isLoading: false,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapSecondaryButton()
                },
                leftIcon: nil,
                rightIcon: nil,
                iconTintColor: Asset.Colors.textAndIconPrimary.color,
                height: 56,
                cornerRadius: 28
            ),
            isSecondaryButtonHidden: data.step == .account
        )
    }
}

private extension RegistrationPresenter {
    func makeContentViewModel(from data: RegistrationFetchData) -> RegistrationViewModel.ContentViewModel {
        switch data.step {
        case .account:
            return .account(
                .init(
                    title: .init(
                        text: L10n.secureYourAccount,
                        font: Typography.typographyBold26,
                        textColor: Asset.Colors.textAndIconPrimary.color,
                        alignment: .left,
                        numberOfLines: .zero,
                        lineBreakMode: .byWordWrapping
                    ),
                    subtitle: .init(
                        text: L10n.accountStepRegistrationSutitle,
                        font: Typography.typographyMedium20,
                        textColor: Asset.Colors.textAndIconSecondary.color,
                        alignment: .left,
                        numberOfLines: .zero,
                        lineBreakMode: .byWordWrapping
                    ),
                    emailField: .init(
                        text: data.email,
                        placeholder: L10n.emailPlaceholder,
                        titleText: L10n.emailAddress,
                        leftIcon: envelopeImage,
                        helpText: data.emailErrorMessage,
                        helpTextColor: Asset.Colors.errorColor.color,
                        onTextDidChanged: CommandOf { [weak handler] email in
                            await handler?.handleEmailDidChange(email)
                        }
                    ),
                    passwordField: .init(
                        text: data.password,
                        placeholder: L10n.passwordPlaceholder,
                        isSecureTextEntry: true,
                        titleText: L10n.password,
                        leftIcon: lockImage,
                        helpText: data.passwordErrorMessage,
                        helpTextColor: Asset.Colors.errorColor.color,
                        onTextDidChanged: CommandOf { [weak handler] password in
                            await handler?.handlePasswordDidChange(password)
                        },
                        onReturn: Command { [weak handler] in
                            await handler?.handleTapPrimaryButton()
                        }
                    ),
                    confirmPasswordField: .init(
                        text: data.confirmPassword,
                        placeholder: L10n.passwordPlaceholder,
                        isSecureTextEntry: true,
                        titleText: L10n.registrationConfirmPassword,
                        leftIcon: lockRotationImage,
                        helpText: data.confirmPasswordErrorMessage,
                        helpTextColor: Asset.Colors.errorColor.color,
                        onTextDidChanged: CommandOf { [weak handler] confirmPassword in
                            await handler?.handleConfirmPasswordDidChange(confirmPassword)
                        },
                        onReturn: Command { [weak handler] in
                            await handler?.handleTapPrimaryButton()
                        }
                    )
                )
            )

        case .name:
            return .name(
                .init(
                    title: .init(
                        text: L10n.enterYourName,
                        font: Typography.typographyBold26,
                        textColor: Asset.Colors.textAndIconPrimary.color,
                        alignment: .left,
                        numberOfLines: .zero,
                        lineBreakMode: .byWordWrapping
                    ),
                    subtitle: .init(
                        text: L10n.nameStepRegistrationSutitle,
                        font: Typography.typographyMedium20,
                        textColor: Asset.Colors.textAndIconSecondary.color,
                        alignment: .left,
                        numberOfLines: .zero,
                        lineBreakMode: .byWordWrapping
                    ),
                    nameField: .init(
                        text: data.name,
                        placeholder: L10n.registrationNamePlaceholder,
                        titleText: L10n.name,
                        leftIcon: personImage,
                        helpText: data.nameErrorMessage,
                        helpTextColor: Asset.Colors.errorColor.color,
                        onTextDidChanged: CommandOf { [weak handler] name in
                            await handler?.handleNameDidChange(name)
                        },
                        onReturn: Command { [weak handler] in
                            await handler?.handleTapPrimaryButton()
                        }
                    )
                )
            )

        case .currency:
            let popularRows = data.popularCurrencies.map { makeCurrencyRow(from: $0, selectedCurrencyCode: data.selectedCurrencyCode) }
            let otherRows = data.otherCurrencies.map { makeCurrencyRow(from: $0, selectedCurrencyCode: data.selectedCurrencyCode) }

            return .currency(
                .init(
                    title: .init(
                        text: L10n.registrationSelectBaseCurrency,
                        font: Typography.typographyBold26,
                        textColor: Asset.Colors.textAndIconPrimary.color,
                        alignment: .left,
                        numberOfLines: .zero,
                        lineBreakMode: .byWordWrapping
                    ),
                    searchField: .init(
                        text: data.searchQuery,
                        placeholder: L10n.registrationSearchCurrencyPlaceholder,
                        leftIcon: magnifyingglassImage,
                        onTextDidChanged: CommandOf { [weak handler] query in
                            await handler?.handleSearchQueryDidChange(query)
                        }
                    ),
                    errorLabel: data.currencyErrorMessage.map {
                        .init(
                            text: $0,
                            font: Typography.typographyMedium14,
                            textColor: Asset.Colors.errorColor.color,
                            alignment: .left,
                            numberOfLines: .zero,
                            lineBreakMode: .byWordWrapping
                        )
                    },
                    popularSectionTitle: popularRows.isEmpty ? nil : .init(
                        text: L10n.registrationPopularCurrencies,
                        font: Typography.typographyBold12,
                        textColor: Asset.Colors.textAndIconPlaceseholder.color,
                        alignment: .left
                    ),
                    otherSectionTitle: otherRows.isEmpty ? nil : .init(
                        text: L10n.registrationOtherCurrencies,
                        font: Typography.typographyBold12,
                        textColor: Asset.Colors.textAndIconPlaceseholder.color,
                        alignment: .left
                    ),
                    popularRows: popularRows,
                    otherRows: otherRows
                )
            )
        }
    }

    func makeCurrencyRow(
        from currency: RegistrationCurrency,
        selectedCurrencyCode: String?
    ) -> RegistrationViewModel.CurrencyRowViewModel {
        .init(
            title: .init(
                text: currency.title.localizedCapitalized,
                font: Typography.typographySemibold16,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .left
            ),
            subtitle: .init(
                text: currency.code,
                font: Typography.typographyMedium14,
                textColor: Asset.Colors.textAndIconPlaceseholder.color,
                alignment: .left
            ),
            isSelected: currency.code == selectedCurrencyCode,
            tapCommand: Command { [weak handler] in
                await handler?.handleSelectCurrency(currency.code)
            }
        )
    }
}
