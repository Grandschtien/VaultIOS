// Created by Egor Shkarin 23.03.2026

import Foundation

protocol MainBusinessLogic: Sendable {
    func fetchData() async
}

protocol MainHandler: AnyObject, Sendable {
    func handleTapSeeAllCategories() async
    func handleTapSeeAllExpenses() async
    func handleTapCategory(id: String, name: String) async
    func handleTapPeriodButton() async
    func handleTapRetryBlockingError() async
    func handleTapRetrySummary() async
    func handleTapRetryCategories() async
    func handleTapRetryExpenses() async
}

actor MainInteractor: MainBusinessLogic {
    private let presenter: MainPresentationLogic
    private let router: MainRoutingLogic
    private let currencyRateProvider: MainCurrencyRateProviding
    private let summaryProvider: MainSummaryProviding
    private let summaryPeriodProvider: MainSummaryPeriodServicing
    private let subscriptionAccessService: SubscriptionAccessServicing
    private let repository: MainFlowDomainRepositoryProtocol
    private let observer: MainFlowDomainObserverProtocol

    private var blockingErrorDescription: String?
    private var summaryState: LoadingStatus = .idle
    private var categoriesState: LoadingStatus = .idle
    private var expensesState: LoadingStatus = .idle
    private var currentTier: String = ""

    private var summary: MainSummaryModel?
    private var categories: [MainCategoryCardModel] = []
    private var expenseGroups: [MainExpenseGroupModel] = []
    private var observationTask: Task<Void, Never>?

    init(
        presenter: MainPresentationLogic,
        router: MainRoutingLogic,
        currencyRateProvider: MainCurrencyRateProviding,
        summaryProvider: MainSummaryProviding,
        summaryPeriodProvider: MainSummaryPeriodServicing,
        subscriptionAccessService: SubscriptionAccessServicing,
        repository: MainFlowDomainRepositoryProtocol,
        observer: MainFlowDomainObserverProtocol
    ) {
        self.presenter = presenter
        self.router = router
        self.currencyRateProvider = currencyRateProvider
        self.summaryProvider = summaryProvider
        self.summaryPeriodProvider = summaryPeriodProvider
        self.subscriptionAccessService = subscriptionAccessService
        self.repository = repository
        self.observer = observer
    }

    deinit {
        observationTask?.cancel()
    }

    func fetchData() async {
        guard await validateLaunchCurrencyRate() else {
            return
        }

        currentTier = await subscriptionAccessService.currentTier()
        if SubscriptionPlanResolver.hasPremiumTier(for: currentTier) == false {
            summaryPeriodProvider.resetToCurrentMonth()
        }

        startObservingIfNeeded()
        await loadMainData()
    }
}

private extension MainInteractor {
    func startObservingIfNeeded() {
        guard observationTask == nil else {
            return
        }

        let stream = observer.subscribeOverview()
        observationTask = Task { [weak self] in
            for await snapshot in stream {
                guard let self else {
                    return
                }

                await self.handleOverviewSnapshot(snapshot)
            }
        }
    }

    func validateLaunchCurrencyRate() async -> Bool {
        do {
            try await currencyRateProvider.synchronizeCurrencyRateOnLaunch()
            blockingErrorDescription = nil
            return true
        } catch {
            resetLoadedData()
            summaryState = .idle
            categoriesState = .idle
            expensesState = .idle
            blockingErrorDescription = error.localizedDescription
            await presentFetchedData()
            return false
        }
    }

    func loadMainData() async {
        summaryState = .loading
        categoriesState = .loading
        expensesState = .loading

        resetLoadedData()
        await presentFetchedData()

        async let summaryTask: Void = loadSummary()
        async let categoriesTask: Void = loadCategories()
        async let expensesTask: Void = loadExpenses()

        _ = await (summaryTask, categoriesTask, expensesTask)
    }

    func resetLoadedData() {
        summary = nil
        categories = []
        expenseGroups = []
    }

    func loadSummary() async {
        do {
            summary = try await summaryProvider.fetchSummary()
            summaryState = .loaded
        } catch {
            if let overviewSummary = observer.currentOverviewSnapshot().summary {
                summary = MainSummaryModel(
                    totalAmount: overviewSummary.totalAmount,
                    currency: overviewSummary.currency,
                    changePercent: summary?.changePercent ?? overviewSummary.changePercent
                )
                summaryState = .loaded
            } else {
                summaryState = .failed(.undelinedError(description: error.localizedDescription))
            }
        }

        await presentFetchedData()
    }

    func loadCategories() async {
        do {
            try await repository.refreshCategories()
            categories = observer.currentOverviewSnapshot().categories
            categoriesState = .loaded
        } catch {
            categories = observer.currentOverviewSnapshot().categories

            if categories.isEmpty {
                categoriesState = .failed(.undelinedError(description: error.localizedDescription))
            } else {
                categoriesState = .loaded
            }
        }

        await presentFetchedData()
    }

    func loadExpenses() async {
        do {
            try await repository.refreshRecentExpenses()
            expenseGroups = observer.currentOverviewSnapshot().expenseGroups
            expensesState = .loaded
        } catch {
            expenseGroups = observer.currentOverviewSnapshot().expenseGroups

            if expenseGroups.isEmpty {
                expensesState = .failed(.undelinedError(description: error.localizedDescription))
            } else {
                expensesState = .loaded
            }
        }

        await presentFetchedData()
    }

    func handleOverviewSnapshot(_ snapshot: MainFlowOverviewSnapshot) async {
        if let snapshotSummary = snapshot.summary {
            summary = MainSummaryModel(
                totalAmount: snapshotSummary.totalAmount,
                currency: snapshotSummary.currency,
                changePercent: summary?.changePercent ?? snapshotSummary.changePercent
            )
            summaryState = .loaded
        }

        categories = snapshot.categories
        expenseGroups = snapshot.expenseGroups

        guard summaryState == .loaded || categoriesState == .loaded || expensesState == .loaded else {
            return
        }

        await presentFetchedData()
    }

    func presentFetchedData() async {
        await presenter.presentFetchedData(
            MainFetchData(
                blockingErrorDescription: blockingErrorDescription,
                summaryState: summaryState,
                categoriesState: categoriesState,
                expensesState: expensesState,
                summary: summary,
                categories: categories,
                expenseGroups: expenseGroups
            )
        )
    }
}

extension MainInteractor: MainHandler {
    func handleTapSeeAllCategories() async {
        guard blockingErrorDescription == nil else {
            return
        }

        await router.openAllCategories()
    }

    func handleTapSeeAllExpenses() async {
        guard blockingErrorDescription == nil else {
            return
        }

        await router.openAllExpenses()
    }

    func handleTapCategory(id: String, name: String) async {
        guard blockingErrorDescription == nil else {
            return
        }

        await router.openCategory(id: id, name: name)
    }

    func handleTapPeriodButton() async {
        guard blockingErrorDescription == nil else {
            return
        }

        currentTier = await subscriptionAccessService.currentTier()
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

    func handleTapRetryBlockingError() async {
        guard blockingErrorDescription != nil else {
            return
        }

        guard await validateLaunchCurrencyRate() else {
            return
        }

        await loadMainData()
    }

    func handleTapRetrySummary() async {
        guard blockingErrorDescription == nil else {
            return
        }

        summaryState = .loading
        summary = nil

        await presentFetchedData()
        await loadSummary()
    }

    func handleTapRetryCategories() async {
        guard blockingErrorDescription == nil else {
            return
        }

        categoriesState = .loading
        categories = []

        await presentFetchedData()
        await loadCategories()
    }

    func handleTapRetryExpenses() async {
        guard blockingErrorDescription == nil else {
            return
        }

        expensesState = .loading
        expenseGroups = []

        await presentFetchedData()
        await loadExpenses()
    }
}

extension MainInteractor: CategoryPeriodPickerOutput {
    func handleDidConfirmCategoryPeriod(fromDate: Date, to date: Date) async {
        summaryPeriodProvider.updatePeriod(
            from: fromDate,
            to: date
        )
        await loadMainData()
        await repository.refreshLoadedPeriodDependentModules()
    }
}

extension MainInteractor: SubscriptionOutput {
    func handleSubscriptionDidSync() async {
        currentTier = await subscriptionAccessService.refreshCurrentTier()
        if SubscriptionPlanResolver.hasPremiumTier(for: currentTier) == false {
            summaryPeriodProvider.resetToCurrentMonth()
        }
    }
}
