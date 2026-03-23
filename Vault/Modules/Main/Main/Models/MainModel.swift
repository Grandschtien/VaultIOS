// Created by Egor Shkarin 23.03.2026

import Foundation

struct MainSummaryModel: Equatable, Sendable {
    let totalAmount: Double
    let currency: String
    let changePercent: Double
}

struct MainCategoryModel: Equatable, Codable, Sendable {
    let id: String
    let name: String
    let icon: String
    let color: String
}

struct MainCategoryCardModel: Equatable, Codable, Sendable {
    let id: String
    let name: String
    let icon: String
    let color: String
    let amount: Double
    let currency: String
}

struct MainExpenseModel: Equatable, Codable, Sendable {
    let id: String
    let title: String
    let description: String
    let amount: Double
    let currency: String
    let category: String
    let timeOfAdd: Date
}

struct MainExpenseGroupModel: Equatable, Sendable {
    let date: Date
    let expenses: [MainExpenseModel]
}
