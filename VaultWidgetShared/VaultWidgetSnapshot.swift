import Foundation

enum VylokWidgetEntitlementState: String, Codable, Equatable, Sendable {
    case regular
    case subscribed
}

struct VylokWidgetSnapshot: Codable, Equatable, Sendable {
    let entitlementState: VylokWidgetEntitlementState
    let todayAmount: Double?
    let todayCurrency: String?
    let monthAmount: Double?
    let monthCurrency: String?
    let updatedAt: Date

    init(
        entitlementState: VylokWidgetEntitlementState,
        todayAmount: Double?,
        todayCurrency: String?,
        monthAmount: Double?,
        monthCurrency: String?,
        updatedAt: Date
    ) {
        self.entitlementState = entitlementState
        self.todayAmount = todayAmount
        self.todayCurrency = todayCurrency
        self.monthAmount = monthAmount
        self.monthCurrency = monthCurrency
        self.updatedAt = updatedAt
    }
}
