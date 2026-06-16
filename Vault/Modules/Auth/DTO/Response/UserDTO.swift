//
//  UserDTO.swift
//  Vault
//
//  Created by Егор Шкарин on 15.03.2026.
//

import Foundation

struct User: Codable, Equatable, Sendable {
    let id: String
    let email: String
    let emailVerified: Bool?
    let name: String
    let currency: String
    let preferredLanguage: String
    let tier: String

    init(
        id: String,
        email: String,
        emailVerified: Bool? = nil,
        name: String,
        currency: String,
        preferredLanguage: String,
        tier: String
    ) {
        self.id = id
        self.email = email
        self.emailVerified = emailVerified
        self.name = name
        self.currency = currency
        self.preferredLanguage = preferredLanguage
        self.tier = tier
    }
}
