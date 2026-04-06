import Foundation

final class MainFlowContext: Sendable {
    let store: MainFlowDomainStoreProtocol
    let observer: MainFlowDomainObserverProtocol
    let repository: MainFlowDomainRepositoryProtocol
    let summaryPeriodProvider: MainSummaryPeriodServicing

    init(
        store: MainFlowDomainStoreProtocol,
        observer: MainFlowDomainObserverProtocol,
        repository: MainFlowDomainRepositoryProtocol,
        summaryPeriodProvider: MainSummaryPeriodServicing
    ) {
        self.store = store
        self.observer = observer
        self.repository = repository
        self.summaryPeriodProvider = summaryPeriodProvider
    }
}
