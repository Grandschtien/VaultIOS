import Foundation
@testable import Vylok

enum LoginResponseDTOFixtures {
    static func makeUser(
        id: String = "user-1",
        email: String = "jane@example.com",
        name: String = "Jane Doe",
        currency: String = "USD",
        preferredLanguage: String = "en",
        tier: String = "REGULAR"
    ) -> User {
        User(
            id: id,
            email: email,
            emailVerified: true,
            name: name,
            currency: currency,
            preferredLanguage: preferredLanguage,
            tier: tier
        )
    }

    static func makeResponse(
        accessToken: String = "access",
        refreshToken: String = "refresh",
        tokenType: String = "Bearer",
        expiresIn: Int = 900,
        user: User = makeUser()
    ) -> LoginResponseDTO {
        LoginResponseDTO(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenType: tokenType,
            expiresIn: expiresIn,
            user: user
        )
    }
}
