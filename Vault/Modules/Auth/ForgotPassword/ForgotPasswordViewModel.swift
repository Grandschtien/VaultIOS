import UIKit

struct ForgotPasswordViewModel: Equatable {
    let closeButton: CloseButtonViewModel
    let title: Label.LabelViewModel
    let emailField: TextField.ViewModel
    let sendButton: Button.ButtonViewModel

    init(
        closeButton: CloseButtonViewModel = .init(),
        title: Label.LabelViewModel = .init(),
        emailField: TextField.ViewModel = .init(),
        sendButton: Button.ButtonViewModel = .init()
    ) {
        self.closeButton = closeButton
        self.title = title
        self.emailField = emailField
        self.sendButton = sendButton
    }
}

extension ForgotPasswordViewModel {
    struct CloseButtonViewModel: Equatable {
        let isEnabled: Bool
        let tapCommand: Command

        init(isEnabled: Bool = true, tapCommand: Command = .nope) {
            self.isEnabled = isEnabled
            self.tapCommand = tapCommand
        }
    }
}
