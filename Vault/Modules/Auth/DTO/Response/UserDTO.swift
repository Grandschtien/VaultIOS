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
    let name: String
    let currency: String
    let preferredLanguage: String
    let tier: String
}
