import Foundation

protocol AnalyticsBusinessLogic: Sendable {
    func fetchData() async
}

protocol AnalyticsHandler: AnyObject, Sendable {
    func handleTapRetry() async
    func handleTapMonthFilter() async
    func handleSelectPreset(_ preset: AnalyticsPeriodPreset) async
    func handleTapCategory(id: String, name: String) async
    func handleTapSubscribe() async
}

actor AnalyticsInteractor: AnalyticsBusinessLogic {
    private enum LoadPresentation {
        case initial
        case silent
    }

    private struct CachedPresetData {
        let resolution: AnalyticsPeriodResolution
        let data: AnalyticsDataModel
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
    private let dataProvider: AnalyticsDataProviding
    private let observer: MainFlowDomainObserverProtocol
    private let periodResolver: AnalyticsPeriodResolving
    private let subscriptionAccessService: SubscriptionAccessServicing
    private let analytics: AnalyticsModuleAnalyticsTracking?

    private var loadingState: LoadingStatus = .idle
    private var data: AnalyticsDataModel?
    private var presetDataCache: [AnalyticsPeriodPreset: CachedPresetData] = [:]
    private var currentTier: SubscriptionTier = .regular
    private var currentPeriodResolution: AnalyticsPeriodResolution?
    private var observationTask: Task<Void, Never>?
    private var didReceiveInitialObserverEvent = false
    private var hasTrackedScreenOpen: Bool = false
    private var hasShownContentShell: Bool = false

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
        if hasShownContentShell {
            await refreshCurrentDataSilently(for: resolution)
        } else {
            await loadData(
                for: resolution,
                presentation: .initial,
                trackScreenResult: true
            )
        }
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

        await refreshCurrentDataSilently(for: resolvedCurrentPeriod())
    }

    private func loadData(
        for resolution: AnalyticsPeriodResolution,
        presentation: LoadPresentation,
        trackScreenResult: Bool
    ) async {
        switch presentation {
        case .initial:
            data = nil
            loadingState = .loading
            await presentFetchedData(resolution: resolution)
        case .silent:
            break
        }

        if case .initial = presentation {
            await loadInitialPresetData(
                for: resolution,
                trackScreenResult: trackScreenResult
            )
            return
        }

        do {
            let fetchedData = try await dataProvider.fetchData(for: resolution.period)
            cache(fetchedData, for: resolution)
            currentPeriodResolution = resolution
            data = fetchedData
            loadingState = .loaded
            hasShownContentShell = true
            await presentFetchedData(resolution: resolution)
        } catch {
            if data == nil {
                loadingState = .failed(.undelinedError(description: error.localizedDescription))
                await presentFetchedData(resolution: resolution)
            }
        }
    }

    func loadInitialPresetData(
        for resolution: AnalyticsPeriodResolution,
        trackScreenResult: Bool
    ) async {
        let presetResolutions = currentPresetResolutions()
        let results = await fetchPresetData(for: presetResolutions)

        for (preset, result) in results {
            if
                case let .success(model) = result,
                let cachedResolution = presetResolutions[preset]
            {
                presetDataCache[preset] = .init(
                    resolution: cachedResolution,
                    data: model
                )
            }
        }

        guard let selectedPreset = resolution.preset else {
            await loadInitialCustomData(
                for: resolution,
                trackScreenResult: trackScreenResult
            )
            return
        }

        switch results[selectedPreset] {
        case let .success(model):
            currentPeriodResolution = resolution
            data = model
            loadingState = .loaded
            hasShownContentShell = true
            await presentFetchedData(resolution: resolution)
            if trackScreenResult {
                analytics?.trackScreenSuccess()
            }
        case let .failure(error):
            data = nil
            loadingState = .failed(.undelinedError(description: error.localizedDescription))
            await presentFetchedData(resolution: resolution)
            if trackScreenResult {
                analytics?.trackScreenFailure(error)
            }
        case .none:
            data = nil
            loadingState = .failed(.undelinedError(description: L10n.mainOverviewError))
            await presentFetchedData(resolution: resolution)
            if trackScreenResult {
                analytics?.trackScreenFailure(LocalError.unavailableTier)
            }
        }
    }

    func loadInitialCustomData(
        for resolution: AnalyticsPeriodResolution,
        trackScreenResult: Bool
    ) async {
        do {
            let fetchedData = try await dataProvider.fetchData(for: resolution.period)
            currentPeriodResolution = resolution
            data = fetchedData
            loadingState = .loaded
            hasShownContentShell = true
            await presentFetchedData(resolution: resolution)
            if trackScreenResult {
                analytics?.trackScreenSuccess()
            }
        } catch {
            data = nil
            loadingState = .failed(.undelinedError(description: error.localizedDescription))
            await presentFetchedData(resolution: resolution)
            if trackScreenResult {
                analytics?.trackScreenFailure(error)
            }
        }
    }

    func refreshCurrentDataSilently(for resolution: AnalyticsPeriodResolution) async {
        if resolution.preset != nil {
            await refreshPresetCacheSilently(selecting: resolution)
            return
        }

        await loadData(
            for: resolution,
            presentation: .silent,
            trackScreenResult: false
        )
    }

    func refreshPresetCacheSilently(selecting resolution: AnalyticsPeriodResolution) async {
        guard let selectedPreset = resolution.preset else {
            return
        }

        let presetResolutions = currentPresetResolutions()
        let results = await fetchPresetData(for: presetResolutions)

        for (preset, result) in results {
            if
                case let .success(model) = result,
                let cachedResolution = presetResolutions[preset]
            {
                presetDataCache[preset] = .init(
                    resolution: cachedResolution,
                    data: model
                )
            }
        }

        guard
            let updatedResolution = presetResolutions[selectedPreset],
            case let .success(model) = results[selectedPreset]
        else {
            return
        }

        currentPeriodResolution = updatedResolution
        data = model
        loadingState = .loaded
        await presentFetchedData(resolution: updatedResolution)
    }

    func fetchPresetData(
        for resolutions: [AnalyticsPeriodPreset: AnalyticsPeriodResolution]
    ) async -> [AnalyticsPeriodPreset: Result<AnalyticsDataModel, Error>] {
        let dataProvider = self.dataProvider

        return await withTaskGroup(
            of: (AnalyticsPeriodPreset, Result<AnalyticsDataModel, Error>).self,
            returning: [AnalyticsPeriodPreset: Result<AnalyticsDataModel, Error>].self
        ) { group in
            for (preset, resolution) in resolutions {
                group.addTask {
                    do {
                        return (preset, .success(try await dataProvider.fetchData(for: resolution.period)))
                    } catch {
                        return (preset, .failure(error))
                    }
                }
            }

            var results: [AnalyticsPeriodPreset: Result<AnalyticsDataModel, Error>] = [:]
            for await (preset, result) in group {
                results[preset] = result
            }
            return results
        }
    }

    func currentPresetResolutions() -> [AnalyticsPeriodPreset: AnalyticsPeriodResolution] {
        Dictionary(
            uniqueKeysWithValues: AnalyticsPeriodPreset.allCases.map { preset in
                (preset, periodResolver.resolveCurrentPeriod(for: preset))
            }
        )
    }

    func cache(_ data: AnalyticsDataModel, for resolution: AnalyticsPeriodResolution) {
        guard let preset = resolution.preset else {
            return
        }

        presetDataCache[preset] = .init(
            resolution: resolution,
            data: data
        )
    }

    func changePeriod(to resolution: AnalyticsPeriodResolution) async {
        if
            let preset = resolution.preset,
            let cachedData = presetDataCache[preset],
            cachedData.resolution == resolution
        {
            currentPeriodResolution = resolution
            data = cachedData.data
            loadingState = .loaded
            await presentFetchedData(resolution: resolution)
            return
        }

        await loadData(
            for: resolution,
            presentation: hasShownContentShell ? .silent : .initial,
            trackScreenResult: false
        )
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
                showsContentShell: hasShownContentShell
            )
        )
    }
}

extension AnalyticsInteractor: AnalyticsHandler {
    func handleTapRetry() async {
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
            return
        }

        if hasShownContentShell {
            await refreshCurrentDataSilently(for: resolution)
        } else {
            await loadData(
                for: resolution,
                presentation: .initial,
                trackScreenResult: true
            )
        }
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

    func handleSelectPreset(_ preset: AnalyticsPeriodPreset) async {
        guard let subscription = await resolveCurrentSubscription(forceRefresh: false) else {
            await presentUnavailableTierError()
            return
        }

        guard subscription.hasAnalyticsAccess else {
            return
        }

        let updatedResolution = periodResolver.resolveCurrentPeriod(for: preset)
        guard updatedResolution != resolvedCurrentPeriod() else {
            return
        }

        await changePeriod(to: updatedResolution)
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
        if hasShownContentShell {
            await refreshCurrentDataSilently(for: resolution)
        } else {
            await loadData(
                for: resolution,
                presentation: .initial,
                trackScreenResult: false
            )
        }
    }
}
