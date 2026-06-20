import UIKit

struct EmailVerificationViewModel: Equatable {
    let title: Label.LabelViewModel
    let subtitle: Label.LabelViewModel
    let codeInput: EmailVerificationCodeInputView.ViewModel
    let errorLabel: Label.LabelViewModel?
    let resendPrompt: Label.LabelViewModel
    let resendAction: ResendActionViewModel

    init(
        title: Label.LabelViewModel = .init(),
        subtitle: Label.LabelViewModel = .init(),
        codeInput: EmailVerificationCodeInputView.ViewModel = .init(),
        errorLabel: Label.LabelViewModel? = nil,
        resendPrompt: Label.LabelViewModel = .init(),
        resendAction: ResendActionViewModel = .init()
    ) {
        self.title = title
        self.subtitle = subtitle
        self.codeInput = codeInput
        self.errorLabel = errorLabel
        self.resendPrompt = resendPrompt
        self.resendAction = resendAction
    }
}

extension EmailVerificationViewModel {
    struct ResendActionViewModel: Equatable {
        let title: String
        let countdownLabel: Label.LabelViewModel?
        let isEnabled: Bool
        let tapCommand: Command

        init(
            title: String = "",
            countdownLabel: Label.LabelViewModel? = nil,
            isEnabled: Bool = false,
            tapCommand: Command = .nope
        ) {
            self.title = title
            self.countdownLabel = countdownLabel
            self.isEnabled = isEnabled
            self.tapCommand = tapCommand
        }
    }
}
