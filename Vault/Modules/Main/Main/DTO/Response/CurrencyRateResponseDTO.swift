// Created by Egor Shkarin on 25.03.2026

import Foundation

struct CurrencyRateResponseDTO: Codable, Equatable, Sendable {
    let currency: String
    let rateToUsd: Double
    let asOf: String
}
