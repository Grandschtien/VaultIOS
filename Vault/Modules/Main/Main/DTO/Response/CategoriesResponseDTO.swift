// Created by Egor Shkarin on 24.03.2026

import Foundation

struct CategoryDTO: Codable, Equatable, Sendable {
    let id: String
    let name: String
    let icon: String
    let color: String
    let totalSpentUsd: Double?
}

struct CategoryResponseDTO: Codable, Equatable, Sendable {
    let category: CategoryDTO
}

struct CategoriesResponseDTO: Codable, Equatable, Sendable {
    let categories: [CategoryDTO]
}
