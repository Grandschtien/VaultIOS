import Foundation

protocol AnalyticsBusinessLogic: Sendable {
    func fetchData() async
}

protocol AnalyticsHandler: AnyObject, Sendable {
    func handleTapRetry() async
    func handleTapMonthFilter() async
    func handleTapCategory(id: String, name: String) async
    func handleTapSubscribe() async
}

actor AnalyticsInteractor: AnalyticsBusinessLogic {
    private enum LocalError: LocalizedError {
        case unavailableTier

        var errorDescription: String? {
            L10n.mainOverviewError
        }
    }

    private enum Constants {
        static let regularTier = "REGULAR"
    }

    private let presenter: AnalyticsPresentationLogic
    private let router: AnalyticsRoutingLogic
    private let repository: MainFlowDomainRepositoryProtocol
    private let dataProvider: AnalyticsDataProviding
    private let observer: MainFlowDomainObserverProtocol
    private let summaryPeriodProvider: MainSummaryPeriodServicing
    private let subscriptionAccessService: SubscriptionAccessServicing
    private let analytics: AnalyticsModuleAnalyticsTracking?

    private var loadingState: LoadingStatus = .idle
    private var data: AnalyticsDataModel?
    private var currentTier: SubscriptionTier = .regular
    private var observationTask: Task<Void, Never>?
    private var didReceiveInitialObserverEvent = false
    private var hasTrackedScreenOpen: Bool = false

    init(
        presenter: AnalyticsPresentationLogic,
        router: AnalyticsRoutingLogic,
        repository: MainFlowDomainRepositoryProtocol,
        dataProvider: AnalyticsDataProviding,
        observer: MainFlowDomainObserverProtocol,
        summaryPeriodProvider: MainSummaryPeriodServicing,
        subscriptionAccessService: SubscriptionAccessServicing,
        analytics: AnalyticsModuleAnalyticsTracking? = nil
    ) {
        self.presenter = presenter
        self.router = router
        self.repository = repository
        self.dataProvider = dataProvider
        self.observer = observer
        self.summaryPeriodProvider = summaryPeriodProvider
        self.subscriptionAccessService = subscriptionAccessService
        self.analytics = analytics
    }

    deinit {
        observationTask?.cancel()
    }

    func fetchData() async {
        if !hasTrackedScreenOpen {
            analytics?.trackScreenOpen()
            hasTrackedScreenOpen = true
        }

        guard let subscription = await resolveCurrentSubscription(forceRefresh: false) else {
            await presentUnavailableTierError()
            return
        }

        if subscription.hasCustomDateRangeAccess == false {
            summaryPeriodProvider.resetToCurrentMonth()
        }
        guard subscription.hasAnalyticsAccess else {
            data = nil
            loadingState = .idle
            await presentFetchedData(
                period: summaryPeriodProvider.currentMonthPeriod(),
                isLocked: true
            )
            analytics?.trackScreenSuccess()
            return
        }

        startObservingIfNeeded()
        await loadData(
            for: summaryPeriodProvider.currentMonthPeriod(),
            showLoadingWhenEmpty: true
        )
    }
}

private extension AnalyticsInteractor {
    func resolveCurrentSubscription(forceRefresh: Bool) async -> SubscriptionAccessSnapshot? {
        let subscription: SubscriptionAccessSnapshot?
        if forceRefresh {
            subscription = await subscriptionAccessService.refreshCurrentSubscriptionSnapshot()
        } else {
            subscription = await subscriptionAccessService.currentSubscriptionSnapshot()
        }

        currentTier = subscription?.tier ?? .regular
        return subscription
    }

    func presentUnavailableTierError() async {
        data = nil
        loadingState = .failed(.undelinedError(description: L10n.mainOverviewError))
        await presentFetchedData(period: summaryPeriodProvider.currentMonthPeriod())
        analytics?.trackScreenFailure(LocalError.unavailableTier)
    }

    func startObservingIfNeeded() {
        guard observationTask == nil else {
            return
        }

        let stream = observer.subscribeOverview()
        observationTask = Task { [weak self] in
            for await _ in stream {
                guard let self else {
                    return
                }

                await self.handleObserverEvent()
            }
        }
    }

    func handleObserverEvent() async {
        if didReceiveInitialObserverEvent == false {
            didReceiveInitialObserverEvent = true
            return
        }

        await loadData(
            for: summaryPeriodProvider.currentMonthPeriod(),
            showLoadingWhenEmpty: false
        )
    }

    func loadData(
        for period: MainSummaryPeriod,
        showLoadingWhenEmpty: Bool
    ) async {
        if showLoadingWhenEmpty || data == nil {
            loadingState = .loading
            await presentFetchedData(period: period)
        }

        do {
            let fetchedData = try await dataProvider.fetchData(for: period)
            data = fetchedData
            loadingState = .loaded
            if showLoadingWhenEmpty {
                analytics?.trackScreenSuccess()
            }
        } catch {
            if data == nil {
                loadingState = .failed(.undelinedError(description: error.localizedDescription))
                if showLoadingWhenEmpty {
                    analytics?.trackScreenFailure(error)
                }
            } else {
                loadingState = .loaded
                if showLoadingWhenEmpty {
                    analytics?.trackScreenSuccess()
                }
            }
        }

        await presentFetchedData(period: period)
    }

    func changePeriod(to period: MainSummaryPeriod) async {
        data = nil
        loadingState = .loading

        await presentFetchedData(period: period)

        do {
            let fetchedData = try await dataProvider.fetchData(for: period)
            data = fetchedData
            loadingState = .loaded
        } catch {
            loadingState = .failed(.undelinedError(description: error.localizedDescription))
        }

        await presentFetchedData(period: period)
    }

    func presentFetchedData(
        period: MainSummaryPeriod,
        isLocked: Bool = false
    ) async {
        await presenter.presentFetchedData(
            AnalyticsFetchData(
                selectedPeriod: period,
                isLocked: isLocked,
                loadingState: loadingState,
                data: data
            )
        )
    }
}

extension AnalyticsInteractor: AnalyticsHandler {
    func handleTapRetry() async {
        await fetchData()
    }

    func handleTapMonthFilter() async {
        guard let subscription = await resolveCurrentSubscription(forceRefresh: false) else {
            await presentUnavailableTierError()
            return
        }

        guard subscription.hasCustomDateRangeAccess else {
            await router.openSubscription(
                currentTier: subscription.tier,
                output: self
            )
            return
        }

        let period = summaryPeriodProvider.currentMonthPeriod()
        await router.openPeriodPicker(
            selectedFromDate: period.from,
            selectedToDate: period.to,
            output: self
        )
    }

    func handleTapCategory(id: String, name: String) async {
        guard let subscription = await resolveCurrentSubscription(forceRefresh: false) else {
            return
        }

        guard subscription.hasAnalyticsAccess else {
            return
        }

        await router.openCategory(id: id, name: name)
    }

    func handleTapSubscribe() async {
        await router.openSubscription(
            currentTier: currentTier,
            output: self
        )
    }
}

extension AnalyticsInteractor: CategoryPeriodPickerOutput {
    func handleDidConfirmCategoryPeriod(fromDate: Date, to date: Date) async {
        let updatedPeriod = MainSummaryPeriod(
            from: fromDate,
            to: date
        )
        guard updatedPeriod != summaryPeriodProvider.currentMonthPeriod() else {
            return
        }

        summaryPeriodProvider.updatePeriod(
            from: fromDate,
            to: date
        )
        let currentPeriod = summaryPeriodProvider.currentMonthPeriod()
        await changePeriod(to: currentPeriod)
        try? await repository.refreshMainFlow()
        await repository.refreshLoadedPeriodDependentModules()
    }
}

extension AnalyticsInteractor: SubscriptionOutput {
    func handleSubscriptionDidSync() async {
        guard let subscription = await resolveCurrentSubscription(forceRefresh: true) else {
            await presentUnavailableTierError()
            return
        }

        if subscription.hasCustomDateRangeAccess == false {
            summaryPeriodProvider.resetToCurrentMonth()
        }

        guard subscription.hasAnalyticsAccess else {
            data = nil
            loadingState = .idle
            await presentFetchedData(
                period: summaryPeriodProvider.currentMonthPeriod(),
                isLocked: true
            )
            return
        }

        startObservingIfNeeded()
        await loadData(
            for: summaryPeriodProvider.currentMonthPeriod(),
            showLoadingWhenEmpty: true
        )
    }
}
