import Foundation

enum VaultWidgetEntitlementState: String, Codable, Equatable, Sendable {
    case regular
    case subscribed
}

struct VaultWidgetSnapshot: Codable, Equatable, Sendable {
    let entitlementState: VaultWidgetEntitlementState
    let todayAmount: Double?
    let todayCurrency: String?
    let monthAmount: Double?
    let monthCurrency: String?
    let updatedAt: Date

    init(
        entitlementState: VaultWidgetEntitlementState,
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
