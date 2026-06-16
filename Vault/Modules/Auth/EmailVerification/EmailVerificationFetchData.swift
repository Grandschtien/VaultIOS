import Foundation

struct EmailVerificationFetchData: Sendable {
    let loadingState: LoadingStatus
    let email: String
    let code: String
    let resendAvailableIn: Int
    let errorMessage: String?

    init(
        loadingState: LoadingStatus = .idle,
        email: String = "",
        code: String = "",
        resendAvailableIn: Int = 0,
        errorMessage: String? = nil
    ) {
        self.loadingState = loadingState
        self.email = email
        self.code = code
        self.resendAvailableIn = resendAvailableIn
        self.errorMessage = errorMessage
    }
}
