//
//  LoginRequestDTO.swift
//  Vault
//
//  Created by Егор Шкарин on 14.03.2026.
//

import Foundation

struct LoginRequestDTO: Codable, Sendable {
    let provider: LoginProvider
    let email: String
    let password: String
}

extension LoginRequestDTO {
    enum LoginProvider: String, Codable {
        case password
        case apple
    }
}
