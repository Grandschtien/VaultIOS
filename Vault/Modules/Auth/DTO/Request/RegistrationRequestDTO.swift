//
//  RegistrationRequestDTO.swift
//  Vault
//
//  Created by Егор Шкарин on 16.03.2026.
//

import Foundation

struct RegisterRequestDTO: Codable, Sendable {
    let provider: String
    let email: String
    let password: String
    let name: String
    let currency: String
    let preferredLanguage: String
}
