import Foundation

struct ProfileCurrencyDidChangePayload: Equatable, Sendable {
    let previousCurrencyCode: String
    let previousRateToUsd: Double?
    let updatedCurrencyCode: String
    let updatedRateToUsd: Double
}

extension Notification.Name {
    static let profileCurrencyDidChange = Notification.Name("profileCurrencyDidChange")
}
