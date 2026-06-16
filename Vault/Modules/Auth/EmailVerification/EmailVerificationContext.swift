import Foundation

struct EmailVerificationContext: Equatable, Sendable {
    enum Source: Equatable, Sendable {
        case registration
        case login
    }

    let source: Source
    let email: String
    let expiresIn: Int
    let resendAvailableIn: Int
}
