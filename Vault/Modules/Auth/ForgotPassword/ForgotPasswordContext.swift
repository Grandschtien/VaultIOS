import Foundation

struct ForgotPasswordContext: Equatable, Sendable {
    let email: String

    init(email: String = "") {
        self.email = email
    }
}
