//
//  LoginRequestDTO.swift
//  Vault
//
//  Created by Егор Шкарин on 14.03.2026.
//

import Foundation

struct LoginRequestDTO: Codable {
    let provider: String
    let email: String
    let password: String
}
