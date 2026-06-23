import Foundation

protocol PendingVylokRouteStoring: Sendable {
    func store(_ route: VylokRoute)
    func consume() -> VylokRoute?
}

extension Notification.Name {
    static let pendingVaultRouteDidChange = Notification.Name(
        "pendingVaultRouteDidChange"
    )
}

final class PendingVylokRouteStore: PendingVylokRouteStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var pendingRoute: VylokRoute?

    func store(_ route: VylokRoute) {
        lock.lock()
        pendingRoute = route
        lock.unlock()

        NotificationCenter.default.post(
            name: .pendingVaultRouteDidChange,
            object: nil
        )
    }

    func consume() -> VylokRoute? {
        lock.lock()
        defer { lock.unlock() }

        let route = pendingRoute
        pendingRoute = nil
        return route
    }
}
