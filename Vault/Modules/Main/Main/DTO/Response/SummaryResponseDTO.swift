// Created by Egor Shkarin on 24.03.2026

import Foundation

struct SummaryByCategoryDTO: Codable, Equatable, Sendable {
    let category: String
    let total: Double
}

struct SummaryResponseDTO: Codable, Equatable, Sendable {
    let category: String?
    let total: Double
    let totalUsd: Double?
    let currency: String
    let byCategory: [SummaryByCategoryDTO]?

    init(
        category: String?,
        total: Double,
        totalUsd: Double? = nil,
        currency: String,
        byCategory: [SummaryByCategoryDTO]?
    ) {
        self.category = category
        self.total = total
        self.totalUsd = totalUsd
        self.currency = currency
        self.byCategory = byCategory
    }
}
