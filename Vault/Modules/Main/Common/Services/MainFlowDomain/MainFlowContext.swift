import Foundation

final class MainFlowContext: Sendable {
    let store: MainFlowDomainStoreProtocol
    let observer: MainFlowDomainObserverProtocol
    let repository: MainFlowDomainRepositoryProtocol

    init(
        store: MainFlowDomainStoreProtocol,
        observer: MainFlowDomainObserverProtocol,
        repository: MainFlowDomainRepositoryProtocol
    ) {
        self.store = store
        self.observer = observer
        self.repository = repository
    }
}
