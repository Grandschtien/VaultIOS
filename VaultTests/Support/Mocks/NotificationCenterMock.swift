import Foundation
@testable import Vylok

final class NotificationCenterMock: NotificationCenterServicing, @unchecked Sendable {
    private struct Observer {
        let token: NSObject
        let name: Notification.Name
        let handler: @Sendable () async -> Void
    }

    private var observers: [Observer] = []

    private(set) var addedObserverNames: [Notification.Name] = []
    private(set) var removedObserversCount = 0

    func addObserver(
        forName name: Notification.Name,
        handler: @escaping @Sendable () async -> Void
    ) -> NSObjectProtocol {
        let token = NSObject()
        observers.append(Observer(token: token, name: name, handler: handler))
        addedObserverNames.append(name)
        return token
    }

    func removeObserver(_ observer: NSObjectProtocol) {
        removedObserversCount += 1
        observers.removeAll { $0.token === observer }
    }

    /// Calls every handler registered for `name` and returns when all of them have finished.
    func post(name: Notification.Name) async {
        for observer in observers where observer.name == name {
            await observer.handler()
        }
    }
}
