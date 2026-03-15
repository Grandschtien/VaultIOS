//
//  LoginResponseDTO.swift
//  Vault
//
//  Created by Егор Шкарин on 15.03.2026.
//

import Foundation

struct LoginResponseDTO: Codable, Equatable , Sendable{
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
    let user: User
}
