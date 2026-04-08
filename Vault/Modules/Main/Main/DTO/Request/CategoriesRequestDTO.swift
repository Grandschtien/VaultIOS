// Created by Egor Shkarin on 24.03.2026

import Foundation

struct CategoriesQueryParameters: Equatable, Sendable {
    let from: Date?
    let to: Date?

    init(
        from: Date? = nil,
        to: Date? = nil
    ) {
        self.from = from
        self.to = to
    }
}

struct CategoryCreateRequestDTO: Codable, Equatable, Sendable {
    let name: String
    let icon: String
    let color: String
}
