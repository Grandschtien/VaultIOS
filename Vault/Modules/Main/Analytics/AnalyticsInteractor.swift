import Foundation

protocol AnalyticsBusinessLogic: Sendable {
    func fetchData() async
}

protocol AnalyticsHandler: AnyObject, Sendable {
    func handleTapRetry() async
    func handleTapMonthFilter() async
    func handleSelectPreset(_ preset: AnalyticsPeriodPreset) async
    func handleSwipeToPreviousPeriod() async
    func handleSwipeToNextPeriod() async
    func handleTapCategory(id: String, name: String) async
    func handleTapSubscribe() async
}

actor AnalyticsInteractor: AnalyticsBusinessLogic {
    private enum LoadPresentation {
        case initial
        case silent
    }

    private enum DataSource {
        case repository
        case network
    }

    private enum LocalError: LocalizedError {
        case unavailableTier

        var errorDescription: String? {
            L10n.mainOverviewError
        }
    }

    private let presenter: AnalyticsPresentationLogic
    private let router: AnalyticsRoutingLogic
    private let repository: MainFlowDomainRepositoryProtocol
    private let analyticsIntervalRepository: AnalyticsIntervalRepositoryProtocol
    private let dataProvider: AnalyticsDataProviding
    private let observer: MainFlowDomainObserverProtocol
    private let periodResolver: AnalyticsPeriodResolving
    private let subscriptionAccessService: SubscriptionAccessServicing
    private let notificationCenter: NotificationCenter
    private let analytics: AnalyticsModuleAnalyticsTracking?

    private var loadingState: LoadingStatus = .idle
    private var data: AnalyticsDataModel?
    private var canPresentAnalyticsContent = false
    private var currentPeriodResolution: AnalyticsPeriodResolution?
    private var pendingResolution: AnalyticsPeriodResolution?
    private var observationTask: Task<Void, Never>?
    private var subscriptionObservationTask: Task<Void, Never>?
    private var didReceiveInitialObserverEvent = false
    private var hasTrackedScreenOpen: Bool = false
    private var hasShownContentShell: Bool = false

    init(
        presenter: AnalyticsPresentationLogic,
        router: AnalyticsRoutingLogic,
        repository: MainFlowDomainRepositoryProtocol,
        analyticsIntervalRepository: AnalyticsIntervalRepositoryProtocol = AnalyticsIntervalRepository(),
        dataProvider: AnalyticsDataProviding,
        observer: MainFlowDomainObserverProtocol,
        periodResolver: AnalyticsPeriodResolving,
        subscriptionAccessService: SubscriptionAccessServicing,
        notificationCenter: NotificationCenter = .default,
        analytics: AnalyticsModuleAnalyticsTracking? = nil
    ) {
        self.presenter = presenter
        self.router = router
        self.repository = repository
        self.analyticsIntervalRepository = analyticsIntervalRepository
        self.dataProvider = dataProvider
        self.observer = observer
        self.periodResolver = periodResolver
        self.subscriptionAccessService = subscriptionAccessService
        self.notificationCenter = notificationCenter
        self.analytics = analytics
    }

    deinit {
        observationTask?.cancel()
        subscriptionObservationTask?.cancel()
    }

    func fetchData() async {
        startObservingSubscriptionChangesIfNeeded()
        if !hasTrackedScreenOpen {
            analytics?.trackScreenOpen()
            hasTrackedScreenOpen = true
        }

        guard let subscription = await resolveCurrentSubscriptionSnapshot(forceRefresh: false) else {
            await presentUnavailableTierError()
            return
        }

        let resolution = resolvedCurrentPeriod()
        guard subscription.hasAnalyticsAccess else {
            await presentLockedState(resolution: resolution)
            analytics?.trackScreenSuccess()
            return
        }

        canPresentAnalyticsContent = true
        startObservingIfNeeded()
        if hasShownContentShell {
            await refreshCurrentDataSilently(for: resolution)
        } else {
            await loadData(
                for: resolution,
                presentation: .initial,
                trackScreenResult: true,
                source: .repository
            )
        }
    }
}

private extension AnalyticsInteractor {
    func resolveCurrentSubscriptionSnapshot(forceRefresh: Bool) async -> SubscriptionAccessSnapshot? {
        if forceRefresh {
            return await subscriptionAccessService.refreshCurrentSubscriptionSnapshot()
        }

        return await subscriptionAccessService.currentSubscriptionSnapshot()
    }

    func presentUnavailableTierError() async {
        canPresentAnalyticsContent = false
        pendingResolution = nil
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

    func displayedCurrentPeriod() -> AnalyticsPeriodResolution {
        pendingResolution ?? resolvedCurrentPeriod()
    }

    func startObservingSubscriptionChangesIfNeeded() {
        guard subscriptionObservationTask == nil else {
            return
        }

        let notificationCenter = notificationCenter
        subscriptionObservationTask = Task { [weak self] in
            for await notification in notificationCenter.notifications(
                named: .subscriptionAccessDidChange
            ) {
                guard !Task.isCancelled,
                      let self,
                      let snapshot = notification.object as? SubscriptionAccessSnapshot else {
                    continue
                }

                if snapshot.hasSameSemanticStatus(
                    as: notification.previousSubscriptionAccessSnapshot
                ) {
                    continue
                }

                await self.handleSubscriptionAccessDidChange(snapshot)
            }
        }
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

    func stopObservingOverview() {
        observationTask?.cancel()
        observationTask = nil
        didReceiveInitialObserverEvent = false
    }

    func handleObserverEvent() async {
        if didReceiveInitialObserverEvent == false {
            didReceiveInitialObserverEvent = true
            return
        }

        await refreshCurrentDataSilently(for: resolvedCurrentPeriod())
    }

    func handleSubscriptionAccessDidChange(
        _ snapshot: SubscriptionAccessSnapshot
    ) async {
        guard snapshot.hasAnalyticsAccess == false else {
            return
        }

        guard canPresentAnalyticsContent else {
            return
        }

        await presentLockedState(resolution: resolvedCurrentPeriod())
    }

    func presentLockedState(resolution: AnalyticsPeriodResolution) async {
        canPresentAnalyticsContent = false
        stopObservingOverview()
        pendingResolution = nil
        data = nil
        loadingState = .idle
        hasShownContentShell = false
        await presentFetchedData(
            resolution: resolution,
            isLocked: true
        )
    }

    private func loadData(
        for resolution: AnalyticsPeriodResolution,
        presentation: LoadPresentation,
        trackScreenResult: Bool,
        source: DataSource
    ) async {
        if case .repository = source,
           let cachedData = await analyticsIntervalRepository.cachedData(for: resolution) {
            pendingResolution = nil
            currentPeriodResolution = resolution
            data = cachedData
            loadingState = .loaded
            hasShownContentShell = true
            await presentFetchedData(resolution: resolution)
            if trackScreenResult {
                analytics?.trackScreenSuccess()
            }
            return
        }

        switch presentation {
        case .initial:
            pendingResolution = nil
            data = nil
            loadingState = .loading
            await presentFetchedData(resolution: resolution)
        case .silent:
            break
        }

        do {
            let fetchedData = try await dataProvider.fetchData(for: resolution.period)
            guard canPresentAnalyticsContent else {
                return
            }

            await analyticsIntervalRepository.save(data: fetchedData, for: resolution)
            pendingResolution = nil
            currentPeriodResolution = resolution
            data = fetchedData
            loadingState = .loaded
            hasShownContentShell = true
            await presentFetchedData(resolution: resolution)
            if trackScreenResult {
                analytics?.trackScreenSuccess()
            }
        } catch {
            if data == nil {
                pendingResolution = nil
                loadingState = .failed(.undelinedError(description: error.localizedDescription))
                await presentFetchedData(resolution: resolution)
            }
            if trackScreenResult {
                analytics?.trackScreenFailure(error)
            }
        }
    }

    func refreshCurrentDataSilently(for resolution: AnalyticsPeriodResolution) async {
        await loadData(
            for: resolution,
            presentation: .silent,
            trackScreenResult: false,
            source: .network
        )
    }

    func changePeriod(to resolution: AnalyticsPeriodResolution) async {
        await loadData(
            for: resolution,
            presentation: hasShownContentShell ? .silent : .initial,
            trackScreenResult: false,
            source: .repository
        )
    }

    func changePeriodBySwipe(to resolution: AnalyticsPeriodResolution) async {
        let previousResolution = resolvedCurrentPeriod()

        if let cachedData = await analyticsIntervalRepository.cachedData(for: resolution) {
            pendingResolution = nil
            currentPeriodResolution = resolution
            data = cachedData
            loadingState = .loaded
            hasShownContentShell = true
            await presentFetchedData(resolution: resolution)
            return
        }

        pendingResolution = resolution
        loadingState = .loading
        await presentFetchedData(resolution: resolution)

        do {
            let fetchedData = try await dataProvider.fetchData(for: resolution.period)
            guard canPresentAnalyticsContent else {
                pendingResolution = nil
                return
            }

            await analyticsIntervalRepository.save(data: fetchedData, for: resolution)
            pendingResolution = nil
            currentPeriodResolution = resolution
            data = fetchedData
            loadingState = .loaded
            hasShownContentShell = true
            await presentFetchedData(resolution: resolution)
        } catch {
            guard canPresentAnalyticsContent else {
                pendingResolution = nil
                return
            }

            pendingResolution = nil
            if data == nil {
                loadingState = .failed(.undelinedError(description: error.localizedDescription))
                await presentFetchedData(resolution: previousResolution)
                return
            }

            loadingState = .loaded
            await presentFetchedData(resolution: previousResolution)
        }
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
                data: data,
                showsContentShell: hasShownContentShell,
                isBodyLoading: pendingResolution != nil && loadingState == .loading
            )
        )
    }

}

extension AnalyticsInteractor: AnalyticsHandler {
    func handleTapRetry() async {
        guard let subscription = await resolveCurrentSubscriptionSnapshot(forceRefresh: false) else {
            await presentUnavailableTierError()
            return
        }

        let resolution = resolvedCurrentPeriod()
        guard subscription.hasAnalyticsAccess else {
            await presentLockedState(resolution: resolution)
            return
        }

        canPresentAnalyticsContent = true
        if hasShownContentShell {
            await refreshCurrentDataSilently(for: resolution)
        } else {
            await loadData(
                for: resolution,
                presentation: .initial,
                trackScreenResult: true,
                source: .repository
            )
        }
    }

    func handleTapMonthFilter() async {
        guard let subscription = await resolveCurrentSubscriptionSnapshot(forceRefresh: false) else {
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

        let period = displayedCurrentPeriod().period
        await router.openPeriodPicker(
            selectedFromDate: period.from,
            selectedToDate: period.to,
            output: self
        )
    }

    func handleSelectPreset(_ preset: AnalyticsPeriodPreset) async {
        guard canPresentAnalyticsContent,
              pendingResolution == nil else {
            return
        }

        let updatedResolution = periodResolver.resolveCurrentPeriod(for: preset)
        guard updatedResolution != resolvedCurrentPeriod() else {
            return
        }

        await changePeriod(to: updatedResolution)
    }

    func handleTapCategory(id: String, name: String) async {
        guard canPresentAnalyticsContent else {
            return
        }

        await router.openCategory(
            id: id,
            name: name,
            period: resolvedCurrentPeriod().period
        )
    }

    func handleSwipeToPreviousPeriod() async {
        guard canPresentAnalyticsContent,
              pendingResolution == nil else {
            return
        }

        let currentResolution = resolvedCurrentPeriod()
        guard currentResolution.preset != nil else {
            return
        }

        let updatedResolution = periodResolver.previousPeriod(for: currentResolution)
        guard updatedResolution != currentResolution else {
            return
        }

        await changePeriodBySwipe(to: updatedResolution)
    }

    func handleSwipeToNextPeriod() async {
        guard canPresentAnalyticsContent,
              pendingResolution == nil else {
            return
        }

        let currentResolution = resolvedCurrentPeriod()
        guard currentResolution.preset != nil else {
            return
        }

        let updatedResolution = periodResolver.nextPeriod(for: currentResolution)
        guard updatedResolution != currentResolution else {
            return
        }

        await changePeriodBySwipe(to: updatedResolution)
    }

    func handleTapSubscribe() async {
        let currentTier = await resolveCurrentSubscriptionSnapshot(forceRefresh: false)?.tier ?? .regular
        await router.openSubscription(
            currentTier: currentTier,
            output: self
        )
    }
}

extension AnalyticsInteractor: CategoryPeriodPickerOutput {
    func handleDidConfirmCategoryPeriod(fromDate: Date, to date: Date) async {
        guard pendingResolution == nil else {
            return
        }

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
        guard let subscription = await resolveCurrentSubscriptionSnapshot(forceRefresh: true) else {
            await presentUnavailableTierError()
            return
        }

        let resolution = resolvedCurrentPeriod()
        guard subscription.hasAnalyticsAccess else {
            await presentLockedState(resolution: resolution)
            return
        }

        canPresentAnalyticsContent = true
        startObservingIfNeeded()
        if hasShownContentShell {
            await refreshCurrentDataSilently(for: resolution)
        } else {
            await loadData(
                for: resolution,
                presentation: .initial,
                trackScreenResult: false,
                source: .repository
            )
        }
    }
}
