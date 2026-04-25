import Foundation

struct ResetPasswordRequestDTO: Codable, Equatable, Sendable {
    let token: String
    let password: String
}
