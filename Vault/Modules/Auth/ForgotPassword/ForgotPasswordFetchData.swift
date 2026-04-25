import Foundation

struct ForgotPasswordFetchData: Sendable {
    let loadingState: LoadingStatus
    let email: String
    let emailErrorMessage: String?

    init(
        loadingState: LoadingStatus = .idle,
        email: String = "",
        emailErrorMessage: String? = nil
    ) {
        self.loadingState = loadingState
        self.email = email
        self.emailErrorMessage = emailErrorMessage
    }
}
