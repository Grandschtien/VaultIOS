import Foundation

enum VylokWidgetEntryDestination: Equatable, Sendable {
    case aiEntry
    case manualEntry
}

protocol VylokWidgetEntryDestinationResolving: Sendable {
    func resolveDestination() async -> VylokWidgetEntryDestination
}

final class VylokWidgetEntryDestinationResolver: VylokWidgetEntryDestinationResolving, @unchecked Sendable {
    private let subscriptionAccessService: SubscriptionAccessServicing

    init(subscriptionAccessService: SubscriptionAccessServicing) {
        self.subscriptionAccessService = subscriptionAccessService
    }

    func resolveDestination() async -> VylokWidgetEntryDestination {
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
