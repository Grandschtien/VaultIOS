import Foundation

struct AIParsedExpenseDTO: Codable, Equatable, Sendable {
    let title: String
    let amount: Double
    let currency: String
    let category: String
    let suggestedCategory: String?
    let confidence: Double
}

struct AIParseUsageDTO: Codable, Equatable, Sendable {
    let entriesUsed: Int
    let entriesLimit: Int
    let resetsAt: Date
}

struct AIParseResponseDTO: Codable, Equatable, Sendable {
    let expenses: [AIParsedExpenseDTO]
    let usage: AIParseUsageDTO
    let error: String?
}
