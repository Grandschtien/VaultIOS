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
    private let presenter: AnalyticsPresentationLogic
    private let router: AnalyticsRoutingLogic
    private let dataProvider: AnalyticsDataProviding
    private let observer: MainFlowDomainObserverProtocol
    private let summaryPeriodProvider: MainSummaryPeriodServicing
    private let subscriptionAccessService: SubscriptionAccessServicing

    private var loadingState: LoadingStatus = .idle
    private var data: AnalyticsDataModel?
    private var currentTier: String = ""
    private var observationTask: Task<Void, Never>?
    private var didReceiveInitialObserverEvent = false

    init(
        presenter: AnalyticsPresentationLogic,
        router: AnalyticsRoutingLogic,
        dataProvider: AnalyticsDataProviding,
        observer: MainFlowDomainObserverProtocol,
        summaryPeriodProvider: MainSummaryPeriodServicing,
        subscriptionAccessService: SubscriptionAccessServicing
    ) {
        self.presenter = presenter
        self.router = router
        self.dataProvider = dataProvider
        self.observer = observer
        self.summaryPeriodProvider = summaryPeriodProvider
        self.subscriptionAccessService = subscriptionAccessService
    }

    deinit {
        observationTask?.cancel()
    }

    func fetchData() async {
        guard let currentTier = await resolveCurrentTier(forceRefresh: false) else {
            await presentUnavailableTierError()
            return
        }

        if SubscriptionPlanResolver.hasPremiumTier(for: currentTier) == false {
            summaryPeriodProvider.resetToCurrentMonth()
        }
        guard SubscriptionPlanResolver.hasPremiumAccess(for: currentTier) else {
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

private extension AnalyticsInteractor {
    func resolveCurrentTier(forceRefresh: Bool) async -> String? {
        let tierState: SubscriptionTierState
        if forceRefresh {
            tierState = await subscriptionAccessService.refreshCurrentTierState()
        } else {
            tierState = await subscriptionAccessService.currentTierState()
        }

        switch tierState {
        case let .resolved(tier):
            currentTier = tier
            return tier
        case .unavailable:
            currentTier = ""
            return nil
        }
    }

    func presentUnavailableTierError() async {
        data = nil
        loadingState = .failed(.undelinedError(description: L10n.mainOverviewError))
        await presentFetchedData(period: summaryPeriodProvider.currentMonthPeriod())
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
        } catch {
            if data == nil {
                loadingState = .failed(.undelinedError(description: error.localizedDescription))
            } else {
                loadingState = .loaded
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
        guard let currentTier = await resolveCurrentTier(forceRefresh: false) else {
            await presentUnavailableTierError()
            return
        }

        guard SubscriptionPlanResolver.hasPremiumTier(for: currentTier) else {
            await router.openSubscription(
                currentTier: currentTier,
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
        guard let currentTier = await resolveCurrentTier(forceRefresh: false) else {
            return
        }

        guard SubscriptionPlanResolver.hasPremiumAccess(for: currentTier) else {
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
        await changePeriod(to: summaryPeriodProvider.currentMonthPeriod())
    }
}

extension AnalyticsInteractor: SubscriptionOutput {
    func handleSubscriptionDidSync() async {
        guard let currentTier = await resolveCurrentTier(forceRefresh: true) else {
            await presentUnavailableTierError()
            return
        }

        if SubscriptionPlanResolver.hasPremiumTier(for: currentTier) == false {
            summaryPeriodProvider.resetToCurrentMonth()
        }

        guard SubscriptionPlanResolver.hasPremiumAccess(for: currentTier) else {
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
