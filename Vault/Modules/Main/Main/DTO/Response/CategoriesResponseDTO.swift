// Created by Egor Shkarin on 24.03.2026

import Foundation

struct CategoryDTO: Codable, Equatable, Sendable {
    let id: String
    let name: String
    let icon: String
    let color: String
    let totalSpentUsd: Double?
    let totalSpent: Double?
    let currency: String?

    init(
        id: String,
        name: String,
        icon: String,
        color: String,
        totalSpentUsd: Double? = nil,
        totalSpent: Double? = nil,
        currency: String? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.totalSpentUsd = totalSpentUsd
        self.totalSpent = totalSpent
        self.currency = currency
    }
}

struct CategoryResponseDTO: Codable, Equatable, Sendable {
    let category: CategoryDTO
}

struct CategoriesResponseDTO: Codable, Equatable, Sendable {
    let categories: [CategoryDTO]
}

extension CategoryDTO {
    var displayedAmount: Double {
        totalSpent ?? totalSpentUsd ?? .zero
    }

    var displayedCurrency: String {
        let normalizedCurrencyCode = currency?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        if let normalizedCurrencyCode,
           !normalizedCurrencyCode.isEmpty,
           totalSpent != nil {
            return normalizedCurrencyCode
        }

        return "USD"
    }
}
