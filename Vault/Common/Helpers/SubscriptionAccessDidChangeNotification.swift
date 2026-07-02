import Foundation

extension Notification.Name {
    static let subscriptionAccessDidChange = Notification.Name("subscriptionAccessDidChange")
}

enum SubscriptionAccessDidChangeNotificationUserInfoKey {
    static let previousSnapshot = "previousSnapshot"
}

extension Notification {
    var previousSubscriptionAccessSnapshot: SubscriptionAccessSnapshot? {
        userInfo?[SubscriptionAccessDidChangeNotificationUserInfoKey.previousSnapshot]
            as? SubscriptionAccessSnapshot
    }
}
