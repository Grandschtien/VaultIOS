// Created by Egor Shkarin 29.03.2026

import Foundation

struct ProfileUpdateRequestDTO: Codable, Equatable, Sendable {
    let name: String?
    let currency: String?
    let preferredLanguage: String?

    init(
        name: String? = nil,
        currency: String? = nil,
        preferredLanguage: String? = nil
    ) {
        self.name = name
        self.currency = currency
        self.preferredLanguage = preferredLanguage
    }
}
