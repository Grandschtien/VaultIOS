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

    private var fromDate: Date
    private var loadingState: LoadingStatus = .idle
    private var category: MainCategoryCardModel?
    private var expenseGroups: [MainExpenseGroupModel] = []
    private var deletingExpenseIDs: Set<String> = []
    private var isLoadingNextPage: Bool = false
    private var hasMore: Bool = false
    private var observationTask: Task<Void, Never>?

    init(
        categoryID: String,
        categoryName: String?,
        initialFromDate: Date,
        presenter: CategoryPresentationLogic,
        router: CategoryRoutingLogic,
        repository: MainFlowDomainRepositoryProtocol,
        observer: MainFlowDomainObserverProtocol
    ) {
        self.categoryID = categoryID
        self.categoryName = categoryName
        self.fromDate = initialFromDate
        self.presenter = presenter
        self.router = router
        self.repository = repository
        self.observer = observer
    }

    deinit {
        observationTask?.cancel()
    }

    func fetchData() async {
        startObservingIfNeeded()

        loadingState = .loading
        category = nil
        expenseGroups = []
        deletingExpenseIDs = []
        isLoadingNextPage = false
        hasMore = false

        await presentFetchedData()

        do {
            try await repository.refreshCategoryFirstPage(
                id: categoryID,
                fromDate: fromDate
            )
            syncFromObserver()
            loadingState = .loaded
        } catch {
            syncFromObserver()

            if category == nil && expenseGroups.isEmpty {
                loadingState = .failed(.undelinedError(description: error.localizedDescription))
            } else {
                loadingState = .loaded
            }
        }

        await presentFetchedData()
    }
}

private extension CategoryInteractor {
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
        category = snapshot.category
        expenseGroups = snapshot.expenseGroups
        deletingExpenseIDs = snapshot.deletingExpenseIDs
        hasMore = snapshot.hasMore
    }

    func handleSnapshot(_ snapshot: MainFlowCategorySnapshot) async {
        if loadingState == .loaded, snapshot.category == nil {
            await router.close()
            return
        }

        category = snapshot.category
        expenseGroups = snapshot.expenseGroups
        deletingExpenseIDs = snapshot.deletingExpenseIDs
        hasMore = snapshot.hasMore

        if loadingState == .loaded || snapshot.hasContent || !snapshot.deletingExpenseIDs.isEmpty {
            await presentFetchedData()
        }
    }

    func presentFetchedData() async {
        await presenter.presentFetchedData(
            CategoryFetchData(
                navigationTitle: currentNavigationTitle(),
                fromDate: fromDate,
                loadingState: loadingState,
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
        await fetchData()
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
