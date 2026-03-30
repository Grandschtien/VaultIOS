// Created by Egor Shkarin 29.03.2026

import Foundation

struct ProfileResponseDTO: Codable, Equatable, Sendable {
    let id: String
    let email: String?
    let name: String
    let currency: String
    let preferredLanguage: String
    let tier: String
    let tierValidUntil: Date?
}
