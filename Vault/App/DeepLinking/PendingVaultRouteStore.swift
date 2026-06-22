import Foundation

protocol PendingVaultRouteStoring: Sendable {
    func store(_ route: VaultRoute)
    func consume() -> VaultRoute?
}

extension Notification.Name {
    static let pendingVaultRouteDidChange = Notification.Name(
        "pendingVaultRouteDidChange"
    )
}

final class PendingVaultRouteStore: PendingVaultRouteStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var pendingRoute: VaultRoute?

    func store(_ route: VaultRoute) {
        lock.lock()
        pendingRoute = route
        lock.unlock()

        NotificationCenter.default.post(
            name: .pendingVaultRouteDidChange,
            object: nil
        )
    }

    func consume() -> VaultRoute? {
        lock.lock()
        defer { lock.unlock() }

        let route = pendingRoute
        pendingRoute = nil
        return route
    }
}
