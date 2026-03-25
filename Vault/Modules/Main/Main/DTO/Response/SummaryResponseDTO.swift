// Created by Egor Shkarin on 24.03.2026

import Foundation

struct SummaryByCategoryDTO: Codable, Equatable, Sendable {
    let category: String
    let total: Double
}

struct SummaryResponseDTO: Codable, Equatable, Sendable {
    let category: String?
    let total: Double
    let currency: String
    let byCategory: [SummaryByCategoryDTO]?
}
