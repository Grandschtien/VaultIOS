import Foundation

struct VaultWidgetSnapshot: Codable, Equatable, Sendable {
    let todayAmount: Double
    let todayCurrency: String
    let monthAmount: Double
    let monthCurrency: String
    let updatedAt: Date

    init(
        todayAmount: Double,
        todayCurrency: String,
        monthAmount: Double,
        monthCurrency: String,
        updatedAt: Date
    ) {
        self.todayAmount = todayAmount
        self.todayCurrency = todayCurrency
        self.monthAmount = monthAmount
        self.monthCurrency = monthCurrency
        self.updatedAt = updatedAt
    }
}
