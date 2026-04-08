import Foundation

struct AnalyticsDataModel: Equatable, Sendable {
    let monthStart: Date
    let totalAmount: Double
    let currency: String
    let categories: [AnalyticsCategorySummaryModel]

    var isEmpty: Bool {
        totalAmount <= .zero || categories.isEmpty
    }
}

struct AnalyticsCategorySummaryModel: Equatable, Sendable {
    let id: String
    let name: String
    let icon: String
    let colorValue: String
    let amount: Double
    let currency: String
    let share: Double
    let isInteractive: Bool
}
