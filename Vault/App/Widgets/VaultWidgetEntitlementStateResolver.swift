import Foundation

struct VylokWidgetEntitlementStateResolver {
    func resolve(
        from snapshot: SubscriptionAccessSnapshot?
    ) -> VylokWidgetEntitlementState {
        guard let snapshot else {
            return .regular
        }

        return snapshot.tier == .regular ? .regular : .subscribed
    }
}
