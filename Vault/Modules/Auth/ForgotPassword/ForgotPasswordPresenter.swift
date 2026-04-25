import Foundation
import UIKit
internal import Combine

@MainActor
protocol ForgotPasswordPresentationLogic: Sendable {
    func presentFetchedData(_ data: ForgotPasswordFetchData)
}

final class ForgotPasswordPresenter: ForgotPasswordPresentationLogic, ImageProviding {
    @Published
    private(set) var viewModel: ForgotPasswordViewModel

    weak var handler: ForgotPasswordHandler?

    init(viewModel: ForgotPasswordViewModel) {
        self.viewModel = viewModel
    }

    func presentFetchedData(_ data: ForgotPasswordFetchData) {
        let isLoading = data.loadingState == .loading

        viewModel = ForgotPasswordViewModel(
            closeButton: .init(
                isEnabled: !isLoading,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapClose()
                }
            ),
            title: .init(
                text: L10n.forgotPasswordTitle,
                font: Typography.typographyBold26,
                textColor: Asset.Colors.textAndIconPrimary.color,
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
                isEnabled: !isLoading,
                onTextDidChanged: CommandOf { [weak handler] email in
                    await handler?.handleEmailDidChange(email)
                },
                onReturn: Command { [weak handler] in
                    await handler?.handleTapSend()
                }
            ),
            sendButton: .init(
                title: L10n.forgotPasswordSend,
                titleColor: Asset.Colors.textAndIconPrimaryInverted.color,
                backgroundColor: Asset.Colors.interactiveElemetsPrimary.color,
                font: Typography.typographyBold18,
                isEnabled: !isLoading,
                isLoading: isLoading,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapSend()
                },
                height: 64,
                cornerRadius: 32
            )
        )
    }
}
