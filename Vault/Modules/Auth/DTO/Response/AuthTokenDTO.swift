//
//  AuthTokenDTO.swift
//  Vault
//
//  Created by Egor Shkarin on 15.03.2026.
//

import Foundation

struct AuthTokenDTO: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
    let issuedAt: TimeInterval?

    init(
        accessToken: String,
        refreshToken: String,
        tokenType: String,
        expiresIn: Int,
        issuedAt: TimeInterval? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.issuedAt = issuedAt
    }

    func withIssuedAt(_ issuedAt: TimeInterval) -> AuthTokenDTO {
        AuthTokenDTO(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenType: tokenType,
            expiresIn: expiresIn,
            issuedAt: issuedAt
        )
    }
}
