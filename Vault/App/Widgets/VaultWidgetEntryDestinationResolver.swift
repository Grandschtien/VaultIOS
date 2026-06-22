import Foundation

enum VaultWidgetEntryDestination: Equatable, Sendable {
    case aiEntry
    case manualEntry
}

protocol VaultWidgetEntryDestinationResolving: Sendable {
    func resolveDestination() async -> VaultWidgetEntryDestination
}

final class VaultWidgetEntryDestinationResolver: VaultWidgetEntryDestinationResolving, @unchecked Sendable {
    private let subscriptionAccessService: SubscriptionAccessServicing

    init(subscriptionAccessService: SubscriptionAccessServicing) {
        self.subscriptionAccessService = subscriptionAccessService
    }

    func resolveDestination() async -> VaultWidgetEntryDestination {
        if let currentSnapshot = await subscriptionAccessService.currentSubscriptionSnapshot(),
           currentSnapshot.hasAiInputAccess {
            return .aiEntry
        }

        if let refreshedSnapshot = await subscriptionAccessService.refreshCurrentSubscriptionSnapshot(),
           refreshedSnapshot.hasAiInputAccess {
            return .aiEntry
        }

        return .manualEntry
    }
}
