import Foundation
import NetworkClient

struct AuthErrorResponseDTO: Codable, Equatable, Sendable, CustomError {
    let error: String
    let email: String?
    let expiresIn: Int?
    let resendAvailableIn: Int?

    static func map(data: Data?) -> AuthErrorResponseDTO? {
        guard let data else {
            return nil
        }

        return try? JSONCoder.decoder.decode(Self.self, from: data)
    }

    var errorDescription: String? {
        error
    }
}
