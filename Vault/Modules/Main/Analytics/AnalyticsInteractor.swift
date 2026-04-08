import Foundation

protocol AnalyticsBusinessLogic: Sendable {
    func fetchData() async
}

protocol AnalyticsHandler: AnyObject, Sendable {
    func handleTapRetry() async
    func handleTapMonthFilter() async
    func handleTapCategory(id: String, name: String) async
}

actor AnalyticsInteractor: AnalyticsBusinessLogic {
    private let presenter: AnalyticsPresentationLogic
    private let router: AnalyticsRoutingLogic
    private let dataProvider: AnalyticsDataProviding
    private let observer: MainFlowDomainObserverProtocol
    private let summaryPeriodProvider: MainSummaryPeriodServicing

    private var loadingState: LoadingStatus = .idle
    private var data: AnalyticsDataModel?
    private var observationTask: Task<Void, Never>?
    private var didReceiveInitialObserverEvent = false

    init(
        presenter: AnalyticsPresentationLogic,
        router: AnalyticsRoutingLogic,
        dataProvider: AnalyticsDataProviding,
        observer: MainFlowDomainObserverProtocol,
        summaryPeriodProvider: MainSummaryPeriodServicing
    ) {
        self.presenter = presenter
        self.router = router
        self.dataProvider = dataProvider
        self.observer = observer
        self.summaryPeriodProvider = summaryPeriodProvider
    }

    deinit {
        observationTask?.cancel()
    }

    func fetchData() async {
        startObservingIfNeeded()
        await loadData(
            for: summaryPeriodProvider.currentMonthPeriod(),
            showLoadingWhenEmpty: true
        )
    }
}

private extension AnalyticsInteractor {
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

    func presentFetchedData(period: MainSummaryPeriod) async {
        await presenter.presentFetchedData(
            AnalyticsFetchData(
                selectedPeriod: period,
                loadingState: loadingState,
                data: data
            )
        )
    }
}

extension AnalyticsInteractor: AnalyticsHandler {
    func handleTapRetry() async {
        await loadData(
            for: summaryPeriodProvider.currentMonthPeriod(),
            showLoadingWhenEmpty: true
        )
    }

    func handleTapMonthFilter() async {
        let period = summaryPeriodProvider.currentMonthPeriod()
        await router.openPeriodPicker(
            selectedFromDate: period.from,
            selectedToDate: period.to,
            output: self
        )
    }

    func handleTapCategory(id: String, name: String) async {
        await router.openCategory(id: id, name: name)
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
