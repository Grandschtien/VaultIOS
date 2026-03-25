// Created by Egor Shkarin on 24.03.2026

import Foundation

struct ExpenseCreateItemRequestDTO: Codable, Equatable, Sendable {
    let title: String
    let description: String
    let amount: Double
    let currency: String
    let category: String
    let timeOfAdd: Date
}

struct ExpensesCreateRequestDTO: Codable, Equatable, Sendable {
    let expenses: [ExpenseCreateItemRequestDTO]
}

struct ExpensesListQueryParameters: Equatable, Sendable {
    let category: String?
    let from: Date?
    let to: Date?
    let cursor: String?
    let limit: Int?

    init(
        category: String? = nil,
        from: Date? = nil,
        to: Date? = nil,
        cursor: String? = nil,
        limit: Int? = nil
    ) {
        self.category = category
        self.from = from
        self.to = to
        self.cursor = cursor
        self.limit = limit
    }
}
