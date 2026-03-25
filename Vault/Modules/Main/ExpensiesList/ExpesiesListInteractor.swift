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
    private enum Constants {
        static let pageLimit: Int = 20
    }

    private let presenter: ExpesiesListPresentationLogic
    private let router: ExpesiesListRoutingLogic
    private let expensesProvider: ExpesiesListExpensesProviding
    private let categoriesProvider: ExpesiesListCategoriesProviding
    private let pager: PagerLogic
    private let expenseGrouping: MainExpenseGrouping

    private var loadingState: LoadingStatus = .idle
    private var categories: [MainCategoryModel] = []
    private var expenses: [MainExpenseModel] = []
    private var expenseGroups: [MainExpenseGroupModel] = []
    private var isLoadingNextPage: Bool = false

    init(
        presenter: ExpesiesListPresentationLogic,
        router: ExpesiesListRoutingLogic,
        expensesProvider: ExpesiesListExpensesProviding,
        categoriesProvider: ExpesiesListCategoriesProviding,
        pager: PagerLogic,
        expenseGrouping: MainExpenseGrouping
    ) {
        self.presenter = presenter
        self.router = router
        self.expensesProvider = expensesProvider
        self.categoriesProvider = categoriesProvider
        self.pager = pager
        self.expenseGrouping = expenseGrouping
    }

    func fetchData() async {
        pager.reset()

        loadingState = .loading
        categories = []
        expenses = []
        expenseGroups = []
        isLoadingNextPage = false

        await presentFetchedData()

        await loadInitialPage()
    }
}

private extension ExpesiesListInteractor {
    func loadInitialPage() async {
        guard let request = pager.beginNextPageIfPossible() else {
            return
        }

        do {
            let page = try await expensesProvider.fetchExpensesPage(
                cursor: request.cursor,
                limit: Constants.pageLimit
            )
            expenses = page.expenses
            expenseGroups = expenseGrouping.groupExpenses(expenses)
            loadingState = .loaded
            pager.commitPage(
                nextCursor: page.nextCursor,
                hasMore: page.hasMore
            )
        } catch {
            loadingState = .failed(.undelinedError(description: error.localizedDescription))
            pager.rollbackAfterError()
        }

        await presentFetchedData()
    }

    func presentFetchedData() async {
        let hasMore = pager.hasMorePages()

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

extension ExpesiesListInteractor: ExpesiesListHandler {}

extension ExpesiesListInteractor {
    func handleLoadNextPage() async {
        guard case .loaded = loadingState else {
            return
        }

        guard let request = pager.beginNextPageIfPossible() else {
            return
        }

        isLoadingNextPage = true
        await presentFetchedData()

        do {
            let page = try await expensesProvider.fetchExpensesPage(
                cursor: request.cursor,
                limit: Constants.pageLimit
            )
            expenses.append(contentsOf: page.expenses)
            expenseGroups = expenseGrouping.groupExpenses(expenses)
            isLoadingNextPage = false

            pager.commitPage(
                nextCursor: page.nextCursor,
                hasMore: page.hasMore
            )
        } catch {
            isLoadingNextPage = false
            pager.rollbackAfterError()
            await router.presentError(with: L10n.mainOverviewError)
        }

        await presentFetchedData()
    }

    func handleTapRetry() async {
        await fetchData()
    }
}
