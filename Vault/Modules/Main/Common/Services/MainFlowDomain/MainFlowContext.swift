import Foundation

final class MainFlowContext: Sendable {
    let store: MainFlowDomainStoreProtocol
    let observer: MainFlowDomainObserverProtocol
    let repository: MainFlowDomainRepositoryProtocol
    let analyticsIntervalRepository: AnalyticsIntervalRepositoryProtocol
    let summaryPeriodProvider: MainSummaryPeriodServicing

    init(
        store: MainFlowDomainStoreProtocol,
        observer: MainFlowDomainObserverProtocol,
        repository: MainFlowDomainRepositoryProtocol,
        analyticsIntervalRepository: AnalyticsIntervalRepositoryProtocol,
        summaryPeriodProvider: MainSummaryPeriodServicing
    ) {
        self.store = store
        self.observer = observer
        self.repository = repository
        self.analyticsIntervalRepository = analyticsIntervalRepository
        self.summaryPeriodProvider = summaryPeriodProvider
    }
}
