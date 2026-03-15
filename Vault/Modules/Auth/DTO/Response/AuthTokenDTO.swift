//
//  AuthTokenDTO.swift
//  Vault
//
//  Created by Codex on 15.03.2026.
//

import Foundation

struct AuthTokenDTO: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
}
