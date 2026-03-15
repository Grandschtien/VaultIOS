// Created by Egor Shkarin 14.03.2026

import Foundation
import UIKit
internal import Combine

@MainActor
protocol LoginPresentationLogic: Sendable {
    func presentFetchedData(_ data: LoginFetchData)
}

final class LoginPresenter: LoginPresentationLogic {

    @Published
    private(set) var viewModel: LoginViewModel

    weak var handler: LoginHandler?

    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }

    func presentFetchedData(_ data: LoginFetchData) {
        let isLoading: Bool
        let errorMessage: String?

        switch data.loadingState {
        case .loading:
            isLoading = true
            errorMessage = nil
        case .failed(let error):
            isLoading = false
            errorMessage = error.localizedDescription
        case .idle, .loaded:
            isLoading = false
            errorMessage = nil
        }

        viewModel = LoginViewModel(
            logo: Asset.Icons.loginIcon.image,
            title: Label.LabelViewModel(
                text: L10n.vault,
                font: Typography.typographyBold36,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .center
            ),
            subtitle: Label.LabelViewModel(
                text: L10n.smartExpenseTrackingForYourDigitalLifestyle,
                font: Typography.typographyMedium16,
                textColor: Asset.Colors.textAndIconPlaceseholder.color,
                alignment: .center,
                numberOfLines: .zero,
                lineBreakMode: .byWordWrapping
            ),
            emailField: TextField.ViewModel(
                text: data.email,
                placeholder: L10n.emailPlaceholder,
                titleText: L10n.emailAddress,
                leftIcon: UIImage(systemName: "envelope"),
                onTextDidChanged: CommandOf { [weak handler] email in
                    await handler?.handleEmailDidChange(email)
                }
            ),
            passwordField: TextField.ViewModel(
                text: data.password,
                placeholder: L10n.passwordPlaceholder,
                isSecureTextEntry: true,
                titleText: L10n.password,
                additionalLabelText: L10n.forgot,
                leftIcon: UIImage(systemName: "lock"),
                helpText: errorMessage,
                helpTextColor: .systemRed,
                onTextDidChanged: CommandOf { [weak handler] password in
                    await handler?.handlePasswordDidChange(password)
                },
                onReturn: Command { [weak handler] in
                    await handler?.handleSignInDidTap()
                },
                onAdditionalLabelTap: Command { [weak handler] in
                    await handler?.handleForgotDidTap()
                }
            ),
            signInButton: Button.ButtonViewModel(
                title: L10n.signIn,
                titleColor: Asset.Colors.textAndIconPrimaryInverted.color,
                backgroundColor: Asset.Colors.interactiveElemetsPrimary.color,
                font: Typography.typographyBold18,
                isEnabled: !isLoading,
                tapCommand: Command { [weak handler] in
                    await handler?.handleSignInDidTap()
                },
                rightIcon: Asset.Icons.arrowRight.image,
                iconTintColor: Asset.Colors.textAndIconPrimaryInverted.color,
                height: 64,
                cornerRadius: 32
            ),
            privacyLabel: Label.LabelViewModel(
                text: L10n.privacy.uppercased(),
                font: Typography.typographyBold12,
                textColor: Asset.Colors.textAndIconPlaceseholder.color,
                alignment: .center
            ),
            termsLabel: Label.LabelViewModel(
                text: L10n.terms.uppercased(),
                font: Typography.typographyBold12,
                textColor: Asset.Colors.textAndIconPlaceseholder.color,
                alignment: .center
            ),
            supportLabel: Label.LabelViewModel(
                text: L10n.support.uppercased(),
                font: Typography.typographyBold12,
                textColor: Asset.Colors.textAndIconPlaceseholder.color,
                alignment: .center
            )
        )
    }
}

private extension LoginPresenter {}
