import Foundation

struct VaultWidgetEntitlementStateResolver {
    func resolve(
        from snapshot: SubscriptionAccessSnapshot?
    ) -> VaultWidgetEntitlementState {
        guard let snapshot else {
            return .regular
        }

        return snapshot.tier == .regular ? .regular : .subscribed
    }
}
