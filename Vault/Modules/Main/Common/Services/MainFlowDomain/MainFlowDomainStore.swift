import Foundation

protocol MainFlowDomainStoreProtocol: Sendable {
    func snapshot() -> MainFlowDomainState
    @discardableResult
    func update(_ mutation: (inout MainFlowDomainState) -> Void) -> MainFlowDomainState
    func replaceState(_ state: MainFlowDomainState)
    func clear()
}

final class MainFlowDomainStore: MainFlowDomainStoreProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var state = MainFlowDomainState()

    func snapshot() -> MainFlowDomainState {
        lock.withLock {
            state
        }
    }

    @discardableResult
    func update(_ mutation: (inout MainFlowDomainState) -> Void) -> MainFlowDomainState {
        lock.withLock {
            mutation(&state)
            return state
        }
    }

    func replaceState(_ state: MainFlowDomainState) {
        lock.withLock {
            self.state = state
        }
    }

    func clear() {
        replaceState(.init())
    }
}

private extension NSLock {
    func withLock<T>(_ block: () -> T) -> T {
        lock()
        defer { unlock() }
        return block()
    }
}
