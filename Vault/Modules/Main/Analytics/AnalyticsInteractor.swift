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

    private let presenter: AnalyticsPresentationLogic
    private let router: AnalyticsRoutingLogic
    private let repository: MainFlowDomainRepositoryProtocol
    private let dataProvider: AnalyticsDataProviding
    private let observer: MainFlowDomainObserverProtocol
    private let periodResolver: AnalyticsPeriodResolving
    private let subscriptionAccessService: SubscriptionAccessServicing
    private let analytics: AnalyticsModuleAnalyticsTracking?

    private var loadingState: LoadingStatus = .idle
    private var data: AnalyticsDataModel?
    private var currentTier: SubscriptionTier = .regular
    private var currentPeriodResolution: AnalyticsPeriodResolution?
    private var observationTask: Task<Void, Never>?
    private var didReceiveInitialObserverEvent = false
    private var hasTrackedScreenOpen: Bool = false

    init(
        presenter: AnalyticsPresentationLogic,
        router: AnalyticsRoutingLogic,
        repository: MainFlowDomainRepositoryProtocol,
        dataProvider: AnalyticsDataProviding,
        observer: MainFlowDomainObserverProtocol,
        periodResolver: AnalyticsPeriodResolving,
        subscriptionAccessService: SubscriptionAccessServicing,
        analytics: AnalyticsModuleAnalyticsTracking? = nil
    ) {
        self.presenter = presenter
        self.router = router
        self.repository = repository
        self.dataProvider = dataProvider
        self.observer = observer
        self.periodResolver = periodResolver
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

        let resolution = resolvedCurrentPeriod()
        guard subscription.hasAnalyticsAccess else {
            data = nil
            loadingState = .idle
            await presentFetchedData(
                resolution: resolution,
                isLocked: true
            )
            analytics?.trackScreenSuccess()
            return
        }

        startObservingIfNeeded()
        await loadData(
            for: resolution,
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
        await presentFetchedData(resolution: resolvedCurrentPeriod())
        analytics?.trackScreenFailure(LocalError.unavailableTier)
    }

    func resolvedCurrentPeriod() -> AnalyticsPeriodResolution {
        if let currentPeriodResolution {
            return currentPeriodResolution
        }

        let resolution = periodResolver.defaultPeriod()
        currentPeriodResolution = resolution
        return resolution
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
            for: resolvedCurrentPeriod(),
            showLoadingWhenEmpty: false
        )
    }

    func loadData(
        for resolution: AnalyticsPeriodResolution,
        showLoadingWhenEmpty: Bool
    ) async {
        if showLoadingWhenEmpty || data == nil {
            loadingState = .loading
            await presentFetchedData(resolution: resolution)
        }

        do {
            let fetchedData = try await dataProvider.fetchData(for: resolution.period)
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

        await presentFetchedData(resolution: resolution)
    }

    func changePeriod(to resolution: AnalyticsPeriodResolution) async {
        currentPeriodResolution = resolution
        data = nil
        loadingState = .loading

        await presentFetchedData(resolution: resolution)

        do {
            let fetchedData = try await dataProvider.fetchData(for: resolution.period)
            data = fetchedData
            loadingState = .loaded
        } catch {
            loadingState = .failed(.undelinedError(description: error.localizedDescription))
        }

        await presentFetchedData(resolution: resolution)
    }

    func presentFetchedData(
        resolution: AnalyticsPeriodResolution,
        isLocked: Bool = false
    ) async {
        await presenter.presentFetchedData(
            AnalyticsFetchData(
                selectedPeriod: resolution.period,
                selectedPreset: resolution.preset,
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

        let period = resolvedCurrentPeriod().period
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

        await router.openCategory(
            id: id,
            name: name,
            period: resolvedCurrentPeriod().period
        )
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
        let updatedResolution = periodResolver.resolvePeriod(
            from: fromDate,
            to: date
        )
        guard updatedResolution != resolvedCurrentPeriod() else {
            return
        }

        await changePeriod(to: updatedResolution)
    }
}

extension AnalyticsInteractor: SubscriptionOutput {
    func handleSubscriptionDidSync() async {
        guard let subscription = await resolveCurrentSubscription(forceRefresh: true) else {
            await presentUnavailableTierError()
            return
        }

        let resolution = resolvedCurrentPeriod()
        guard subscription.hasAnalyticsAccess else {
            data = nil
            loadingState = .idle
            await presentFetchedData(
                resolution: resolution,
                isLocked: true
            )
            return
        }

        startObservingIfNeeded()
        await loadData(
            for: resolution,
            showLoadingWhenEmpty: true
        )
    }
}
