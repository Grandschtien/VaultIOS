import Foundation

enum CommonConfirmationCloseAction: Equatable, @unchecked Sendable {
    case close
    case custom(Command)
}

struct CommonConfirmationContext: Equatable, @unchecked Sendable {
    let title: String
    let confirmButtonTitle: String
    let cancelButtonTitle: String
    let confirmCommand: Command
    let cancelAction: CommonConfirmationCloseAction
    let closeAction: CommonConfirmationCloseAction

    init(
        title: String,
        confirmButtonTitle: String,
        cancelButtonTitle: String,
        confirmCommand: Command,
        cancelAction: CommonConfirmationCloseAction = .close,
        closeAction: CommonConfirmationCloseAction = .close
    ) {
        self.title = title
        self.confirmButtonTitle = confirmButtonTitle
        self.cancelButtonTitle = cancelButtonTitle
        self.confirmCommand = confirmCommand
        self.cancelAction = cancelAction
        self.closeAction = closeAction
    }
}
