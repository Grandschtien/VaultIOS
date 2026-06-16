import Foundation

struct EmailVerificationChallengeResponseDTO: Codable, Equatable, Sendable {
    let status: String
    let email: String
    let expiresIn: Int
    let resendAvailableIn: Int
}
