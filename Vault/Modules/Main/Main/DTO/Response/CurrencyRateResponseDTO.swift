// Created by Codex on 25.03.2026

import Foundation

struct CurrencyRateResponseDTO: Codable, Equatable, Sendable {
    let currency: String
    let rate: Double
}
