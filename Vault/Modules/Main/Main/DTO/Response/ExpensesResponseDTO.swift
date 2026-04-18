// Created by Egor Shkarin on 24.03.2026

import Foundation

struct ExpenseDTO: Codable, Equatable, Sendable {
    let id: String
    let title: String
    let description: String?
    let amount: Double
    let currency: String
    var originalAmount: Double? = nil
    var originalCurrency: String? = nil
    let category: String
    let timeOfAdd: Date
}

struct ExpensesCreateResponseDTO: Codable, Equatable, Sendable {
    let expenses: [ExpenseDTO]
}

struct ExpensesListResponseDTO: Codable, Equatable, Sendable {
    let expenses: [ExpenseDTO]
    let nextCursor: String?
    let hasMore: Bool
}
