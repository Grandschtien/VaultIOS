import Foundation
import UIKit
internal import Combine

@MainActor
protocol EmailVerificationPresentationLogic: Sendable {
    func presentFetchedData(_ data: EmailVerificationFetchData)
}

final class EmailVerificationPresenter: EmailVerificationPresentationLogic {
    @Published
    private(set) var viewModel: EmailVerificationViewModel

    weak var handler: EmailVerificationHandler?

    init(viewModel: EmailVerificationViewModel) {
        self.viewModel = viewModel
    }

    func presentFetchedData(_ data: EmailVerificationFetchData) {
        let isLoading = data.loadingState == .loading
        let hasError = data.errorMessage != nil

        viewModel = EmailVerificationViewModel(
            title: .init(
                text: L10n.emailVerificationTitle,
                font: Typography.typographyBold24,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .center,
                numberOfLines: .zero,
                lineBreakMode: .byWordWrapping
            ),
            subtitle: .init(
                text: L10n.emailVerificationSubtitle,
                font: Typography.typographyMedium20,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .center,
                numberOfLines: .zero,
                lineBreakMode: .byWordWrapping
            ),
            codeInput: .init(
                code: data.code,
                isErrorState: hasError,
                isEnabled: !isLoading,
                onCodeDidChange: CommandOf { [weak handler] value in
                    await handler?.handleCodeDidChange(value)
                }
            ),
            errorLabel: data.errorMessage.map {
                .init(
                    text: $0,
                    font: Typography.typographyMedium14,
                    textColor: Asset.Colors.errorColor.color,
                    alignment: .left,
                    numberOfLines: .zero,
                    lineBreakMode: .byWordWrapping
                )
            },
            verifyButton: .init(
                title: L10n.emailVerificationVerify,
                titleColor: Asset.Colors.textAndIconPrimaryInverted.color,
                backgroundColor: Asset.Colors.interactiveElemetsPrimary.color,
                font: Typography.typographyBold18,
                isEnabled: !isLoading,
                isLoading: isLoading,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapVerify()
                },
                height: 64,
                cornerRadius: 32
            ),
            resendPrompt: .init(
                text: L10n.emailVerificationResendPrompt,
                font: Typography.typographyMedium20,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .center
            ),
            resendAction: .init(
                title: L10n.emailVerificationResend.uppercased(),
                countdownLabel: makeCountdownLabel(remainingSeconds: data.resendAvailableIn),
                isEnabled: !isLoading && data.resendAvailableIn == 0,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapResend()
                }
            )
        )
    }
}

private extension EmailVerificationPresenter {
    func makeCountdownLabel(remainingSeconds: Int) -> Label.LabelViewModel? {
        guard remainingSeconds > 0 else {
            return nil
        }

        return .init(
            text: format(seconds: remainingSeconds),
            font: Typography.typographyBold16,
            textColor: Asset.Colors.interactiveElemetsPrimary.color.withAlphaComponent(0.8),
            alignment: .left
        )
    }

    func format(seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
