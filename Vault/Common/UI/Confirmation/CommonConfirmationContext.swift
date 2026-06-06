import Foundation

enum CommonConfirmationButtonStyle: Equatable, Sendable {
    case primary
    case secondary
    case destructive
}

enum CommonConfirmationCloseAction: Equatable, @unchecked Sendable {
    case close
    case custom(Command)
}

struct CommonConfirmationContext: Equatable, @unchecked Sendable {
    let title: String
    let subtitle: String?
    let confirmButtonTitle: String
    let confirmButtonStyle: CommonConfirmationButtonStyle
    let cancelButtonTitle: String
    let cancelButtonStyle: CommonConfirmationButtonStyle
    let confirmCommand: Command
    let cancelAction: CommonConfirmationCloseAction
    let closeAction: CommonConfirmationCloseAction

    init(
        title: String,
        subtitle: String? = nil,
        confirmButtonTitle: String,
        confirmButtonStyle: CommonConfirmationButtonStyle = .primary,
        cancelButtonTitle: String,
        cancelButtonStyle: CommonConfirmationButtonStyle = .secondary,
        confirmCommand: Command,
        cancelAction: CommonConfirmationCloseAction = .close,
        closeAction: CommonConfirmationCloseAction = .close
    ) {
        self.title = title
        self.subtitle = subtitle
        self.confirmButtonTitle = confirmButtonTitle
        self.confirmButtonStyle = confirmButtonStyle
        self.cancelButtonTitle = cancelButtonTitle
        self.cancelButtonStyle = cancelButtonStyle
        self.confirmCommand = confirmCommand
        self.cancelAction = cancelAction
        self.closeAction = closeAction
    }
}
