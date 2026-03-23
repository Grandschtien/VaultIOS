// Created by Egor Shkarin 23.03.2026

import Foundation

protocol MainSummaryProviding: Sendable {
    func fetchSummary() async throws -> MainSummaryModel
}

protocol MainCategoriesProviding: Sendable {
    func fetchCategories() async throws -> [MainCategoryCardModel]
}

protocol MainExpensesProviding: Sendable {
    func fetchExpenses() async throws -> [MainExpenseModel]
}

struct MainSummaryProviderMock: MainSummaryProviding {
    func fetchSummary() async throws -> MainSummaryModel {
        try await Task.sleep(nanoseconds: 4_000_000_000)

        return MainSummaryModel(
            totalAmount: 2450.80,
            currency: "USD",
            changePercent: 12
        )
    }
}

struct MainCategoriesProviderMock: MainCategoriesProviding {
    func fetchCategories() async throws -> [MainCategoryCardModel] {
        try await Task.sleep(nanoseconds: 7_000_000_000)

        return [
            MainCategoryCardModel(
                id: "e3923c47-2608-4004-8467-db2b8e456bea",
                name: "Food",
                icon: "🍴",
                color: "light_orange",
                amount: 450.20,
                currency: "USD"
            ),
            MainCategoryCardModel(
                id: "c633aa94-d93e-49a4-8677-6ff6e45f15f2",
                name: "Transport",
                icon: "🚘",
                color: "light_blue",
                amount: 120.50,
                currency: "USD"
            ),
            MainCategoryCardModel(
                id: "71fd44c2-c1a6-45ec-b0bc-9ca0d90f1b7c",
                name: "Leisure",
                icon: "🎬",
                color: "light_purple",
                amount: 310.00,
                currency: "USD"
            ),
            MainCategoryCardModel(
                id: "7833f0f8-fe9f-4793-a8f0-2ec70c8ce90f",
                name: "Shopping",
                icon: "🛍",
                color: "light_pink",
                amount: 215.75,
                currency: "USD"
            )
        ]
    }
}

struct MainExpensesProviderMock: MainExpensesProviding {
    func fetchExpenses() async throws -> [MainExpenseModel] {
        try await Task.sleep(nanoseconds: 10_000_000_000)

        return [
            MainExpenseModel(
                id: "e44f3bcc-40b9-49df-8fab-9aa95ab198f3",
                title: "Starbucks Coffee",
                description: "Coffee",
                amount: 4.50,
                currency: "USD",
                category: "e3923c47-2608-4004-8467-db2b8e456bea",
                timeOfAdd: date("2025-01-22T08:30:00Z")
            ),
            MainExpenseModel(
                id: "0a0939c7-00e8-4b12-93cf-44988d5f4ce1",
                title: "Uber Ride",
                description: "Taxi",
                amount: 12.20,
                currency: "USD",
                category: "c633aa94-d93e-49a4-8677-6ff6e45f15f2",
                timeOfAdd: date("2025-01-21T22:15:00Z")
            ),
            MainExpenseModel(
                id: "e2fdbe70-c69a-4ce0-86cc-f294bb75f8fa",
                title: "Whole Foods",
                description: "Groceries",
                amount: 64.30,
                currency: "USD",
                category: "e3923c47-2608-4004-8467-db2b8e456bea",
                timeOfAdd: date("2025-01-21T18:00:00Z")
            )
        ]
    }
}

private extension MainExpensesProviderMock {
    func date(_ isoDate: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: isoDate) ?? Date()
    }
}
