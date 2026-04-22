// Created by Egor Shkarin 25.03.2026

import Foundation

protocol ExpesiesListBusinessLogic: Sendable {
    func fetchData() async
}

protocol ExpesiesListHandler: AnyObject, Sendable {
    func handleLoadNextPage() async
    func handleTapRetry() async
}

actor ExpesiesListInteractor: ExpesiesListBusinessLogic {
    private let presenter: ExpesiesListPresentationLogic
    private let router: ExpesiesListRoutingLogic
    private let repository: MainFlowDomainRepositoryProtocol
    private let observer: MainFlowDomainObserverProtocol

    private var loadingState: LoadingStatus = .idle
    private var categories: [MainCategoryModel] = []
    private var expenseGroups: [MainExpenseGroupModel] = []
    private var isLoadingNextPage: Bool = false
    private var hasMore: Bool = false
    private var observationTask: Task<Void, Never>?

    init(
        presenter: ExpesiesListPresentationLogic,
        router: ExpesiesListRoutingLogic,
        repository: MainFlowDomainRepositoryProtocol,
        observer: MainFlowDomainObserverProtocol
    ) {
        self.presenter = presenter
        self.router = router
        self.repository = repository
        self.observer = observer
    }

    deinit {
        observationTask?.cancel()
    }

    func fetchData() async {
        guard loadingState != .loading, !isLoadingNextPage else {
            return
        }

        startObservingIfNeeded()

        loadingState = .loading
        categories = []
        expenseGroups = []
        isLoadingNextPage = false
        hasMore = false

        await presentFetchedData()

        async let categoriesRefresh: Void = refreshCategoriesIfPossible()

        do {
            try await repository.refreshExpensesFirstPage()
            _ = await categoriesRefresh
            syncFromObserver()
            loadingState = .loaded
        } catch {
            _ = await categoriesRefresh
            syncFromObserver()

            if expenseGroups.isEmpty {
                loadingState = .failed(.undelinedError(description: error.localizedDescription))
            } else {
                loadingState = .loaded
            }
        }

        await presentFetchedData()
    }
}

private extension ExpesiesListInteractor {
    func startObservingIfNeeded() {
        guard observationTask == nil else {
            return
        }

        let stream = observer.subscribeExpensesList()
        observationTask = Task { [weak self] in
            for await snapshot in stream {
                guard let self else {
                    return
                }

                await self.handleSnapshot(snapshot)
            }
        }
    }

    func refreshCategoriesIfPossible() async {
        try? await repository.refreshCategories()
    }

    func syncFromObserver() {
        let snapshot = observer.currentExpensesListSnapshot()
        categories = snapshot.categories
        expenseGroups = snapshot.expenseGroups
        hasMore = snapshot.hasMore
    }

    func handleSnapshot(_ snapshot: MainFlowExpensesListSnapshot) async {
        categories = snapshot.categories
        expenseGroups = snapshot.expenseGroups
        hasMore = snapshot.hasMore

        if loadingState == .loaded || !snapshot.expenseGroups.isEmpty {
            await presentFetchedData()
        }
    }

    func presentFetchedData() async {
        await presenter.presentFetchedData(
            ExpesiesListFetchData(
                loadingState: loadingState,
                categories: categories,
                expenseGroups: expenseGroups,
                isLoadingNextPage: isLoadingNextPage,
                hasMore: hasMore
            )
        )
    }
}

extension ExpesiesListInteractor: ExpesiesListHandler {
    func handleLoadNextPage() async {
        guard loadingState == .loaded, hasMore, !isLoadingNextPage else {
            return
        }

        isLoadingNextPage = true
        await presentFetchedData()

        do {
            try await repository.loadNextExpensesPage()
            syncFromObserver()
            isLoadingNextPage = false
        } catch {
            syncFromObserver()
            isLoadingNextPage = false
            await router.presentError(with: L10n.mainOverviewError)
        }

        await presentFetchedData()
    }

    func handleTapRetry() async {
        await fetchData()
    }
}
