import Foundation

struct EmailVerificationRequestDTO: Codable, Equatable, Sendable {
    let email: String
    let code: String
}
