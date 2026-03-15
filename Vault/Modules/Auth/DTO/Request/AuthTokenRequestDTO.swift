//
//  AuthTokenRequestDTO.swift
//  Vault
//
//  Created by Егор Шкарин on 15.03.2026.
//

import Foundation

struct AuthTokenRequestDTO: Codable, Sendable {
    let refreshToken: String
}
