// Created by Egor Shkarin on 28.03.2026

import Foundation

protocol CategoryBusinessLogic: Sendable {
    func fetchData() async
}

protocol CategoryHandler: AnyObject, Sendable {
    func handleTapRetry() async
    func handleLoadNextPage() async
    func handleDeleteExpense(id: String) async
}

actor CategoryInteractor: CategoryBusinessLogic {
    private let categoryID: String
    private let categoryName: String?
    private let presenter: CategoryPresentationLogic
    private let router: CategoryRoutingLogic
    private let repository: MainFlowDomainRepositoryProtocol
    private let observer: MainFlowDomainObserverProtocol
    private let analytics: CategoryAnalyticsTracking?
    private let calendar: Calendar

    private var period: MainSummaryPeriod
    private var loadingState: LoadingStatus = .idle
    private var category: MainCategoryCardModel?
    private var expenseGroups: [MainExpenseGroupModel] = []
    private var deletingExpenseIDs: Set<String> = []
    private var isLoadingNextPage: Bool = false
    private var hasMore: Bool = false
    private var hasCachedDetailForCurrentPeriod: Bool = false
    private var hasCachedSummaryOnly: Bool = false
    private var hasTrackedScreenOpen: Bool = false
    private var observationTask: Task<Void, Never>?

    init(
        categoryID: String,
        categoryName: String?,
        initialPeriod: MainSummaryPeriod,
        presenter: CategoryPresentationLogic,
        router: CategoryRoutingLogic,
        repository: MainFlowDomainRepositoryProtocol,
        observer: MainFlowDomainObserverProtocol,
        calendar: Calendar = .current,
        analytics: CategoryAnalyticsTracking? = nil
    ) {
        self.categoryID = categoryID
        self.categoryName = categoryName
        period = initialPeriod
        self.presenter = presenter
        self.router = router
        self.repository = repository
        self.observer = observer
        self.calendar = calendar
        self.analytics = analytics
    }

    deinit {
        observationTask?.cancel()
    }

    func fetchData() async {
        await fetchData(forceRefresh: false)
    }
}

private extension CategoryInteractor {
    func fetchData(forceRefresh: Bool) async {
        if !hasTrackedScreenOpen {
            analytics?.trackScreenOpen()
            hasTrackedScreenOpen = true
        }

        startObservingIfNeeded()

        isLoadingNextPage = false
        primeStateFromCache()

        if hasCachedDetailForCurrentPeriod, !forceRefresh {
            loadingState = .loaded
            analytics?.trackScreenSuccess()
            await presentFetchedData()
            return
        }

        loadingState = .loading
        await presentFetchedData()

        do {
            try await repository.refreshCategoryFirstPage(
                id: categoryID,
                fromDate: period.from,
                toDate: period.to
            )
            syncFromObserver()
            loadingState = .loaded
            analytics?.trackScreenSuccess()
        } catch {
            syncFromObserver()

            if hasCachedDetailForCurrentPeriod {
                loadingState = .loaded
                analytics?.trackScreenSuccess()
            } else if hasCachedSummaryOnly || (category == nil && expenseGroups.isEmpty) {
                loadingState = .failed(.undelinedError(description: error.localizedDescription))
                analytics?.trackScreenFailure(error)
            } else {
                loadingState = .loaded
                analytics?.trackScreenSuccess()
            }
        }

        await presentFetchedData()
    }
    func startObservingIfNeeded() {
        guard observationTask == nil else {
            return
        }

        let stream = observer.subscribeCategory(id: categoryID)
        observationTask = Task { [weak self] in
            for await snapshot in stream {
                guard let self else {
                    return
                }

                await self.handleSnapshot(snapshot)
            }
        }
    }

    func syncFromObserver() {
        let snapshot = observer.currentCategorySnapshot(id: categoryID)
        guard isSamePeriod(snapshot.period, period) else {
            return
        }

        applyCurrentPeriodSnapshot(snapshot)
    }

    func handleSnapshot(_ snapshot: MainFlowCategorySnapshot) async {
        if loadingState == .loaded, snapshot.category == nil {
            await router.close()
            return
        }

        guard isSamePeriod(snapshot.period, period) else {
            return
        }

        applyCurrentPeriodSnapshot(snapshot)

        let shouldPresentSnapshot: Bool
        switch loadingState {
        case .idle:
            shouldPresentSnapshot = false
        case .loading:
            shouldPresentSnapshot = snapshot.hasContent || !snapshot.deletingExpenseIDs.isEmpty
        case .loaded, .failed:
            shouldPresentSnapshot = true
        }

        if shouldPresentSnapshot {
            await presentFetchedData()
        }
    }

    func primeStateFromCache() {
        if let snapshot = cachedDetailSnapshotForCurrentPeriod() {
            applyCurrentPeriodSnapshot(snapshot)
            return
        }

        if let cachedCategory = cachedCategorySummary() {
            category = cachedCategory
            expenseGroups = []
            deletingExpenseIDs = []
            hasMore = false
            hasCachedDetailForCurrentPeriod = false
            hasCachedSummaryOnly = true
            return
        }

        category = nil
        expenseGroups = []
        deletingExpenseIDs = []
        hasMore = false
        hasCachedDetailForCurrentPeriod = false
        hasCachedSummaryOnly = false
    }

    func cachedDetailSnapshotForCurrentPeriod() -> MainFlowCategorySnapshot? {
        let snapshot = observer.currentCategorySnapshot(id: categoryID)
        guard isSamePeriod(snapshot.period, period), snapshot.category != nil else {
            return nil
        }

        return snapshot
    }

    func cachedCategorySummary() -> MainCategoryCardModel? {
        observer.currentCategoriesSnapshot().categories.first { category in
            category.id == categoryID
        }
    }

    func applyCurrentPeriodSnapshot(_ snapshot: MainFlowCategorySnapshot) {
        hasCachedDetailForCurrentPeriod = snapshot.category != nil
        if hasCachedDetailForCurrentPeriod {
            hasCachedSummaryOnly = false
        }
        apply(snapshot)
    }

    func isSamePeriod(
        _ lhs: MainSummaryPeriod?,
        _ rhs: MainSummaryPeriod
    ) -> Bool {
        guard let lhs else {
            return false
        }

        return calendar.isDate(lhs.from, inSameDayAs: rhs.from)
            && calendar.isDate(lhs.to, inSameDayAs: rhs.to)
    }

    func apply(_ snapshot: MainFlowCategorySnapshot) {
        category = snapshot.category
        expenseGroups = snapshot.expenseGroups
        deletingExpenseIDs = snapshot.deletingExpenseIDs
        hasMore = snapshot.hasMore
    }

    func presentFetchedData() async {
        await presenter.presentFetchedData(
            CategoryFetchData(
                navigationTitle: currentNavigationTitle(),
                fromDate: period.from,
                toDate: period.to,
                loadingState: loadingState,
                hasResolvedCurrentPeriodContent: hasCachedDetailForCurrentPeriod,
                category: category,
                expenseGroups: expenseGroups,
                deletingExpenseIDs: deletingExpenseIDs,
                isLoadingNextPage: isLoadingNextPage,
                hasMore: hasMore
            )
        )
    }

    func currentNavigationTitle() -> String {
        if let name = category?.name, !name.isEmpty {
            return name
        }

        if let categoryName, !categoryName.isEmpty {
            return categoryName
        }

        return L10n.mainOverviewCategories
    }
}

extension CategoryInteractor: CategoryHandler {
    func handleTapRetry() async {
        await fetchData(forceRefresh: true)
    }

    func handleLoadNextPage() async {
        guard loadingState == .loaded, hasMore else {
            return
        }

        isLoadingNextPage = true
        await presentFetchedData()

        do {
            try await repository.loadNextCategoryPage(id: categoryID)
            syncFromObserver()
            isLoadingNextPage = false
        } catch {
            syncFromObserver()
            isLoadingNextPage = false
            await router.presentError(with: L10n.mainOverviewError)
        }

        await presentFetchedData()
    }

    func handleDeleteExpense(id: String) async {
        guard loadingState == .loaded else {
            return
        }

        do {
            try await repository.deleteExpense(id: id)
            syncFromObserver()
            await presentFetchedData()
        } catch {
            syncFromObserver()
            await presentFetchedData()
            await router.presentError(with: L10n.mainOverviewError)
        }
    }
}
