// Created by Egor Shkarin on 28.03.2026

import Foundation

protocol CategoryBusinessLogic: Sendable {
    func fetchData() async
}

protocol CategoryHandler: AnyObject, Sendable {
    func handleTapRetry() async
    func handleLoadNextPage() async
    func handleDeleteExpense(id: String) async
    func handleTapEditButton() async
}

actor CategoryInteractor: CategoryBusinessLogic {
    private enum Constants {
        static let pageLimit: Int = 20
    }

    private struct PendingDeletedExpenseContext {
        let expense: MainExpenseModel
        let index: Int
    }

    private let categoryID: String
    private let categoryName: String?
    private let presenter: CategoryPresentationLogic
    private let router: CategoryRoutingLogic
    private let summaryProvider: CategorySummaryProviding
    private let expensesProvider: CategoryExpensesProviding
    private let pager: PagerLogic
    private let expenseGrouping: MainExpenseGrouping

    private var loadingState: LoadingStatus = .idle
    private var category: MainCategoryCardModel?
    private var expenses: [MainExpenseModel] = []
    private var expenseGroups: [MainExpenseGroupModel] = []
    private var deletingExpenseIDs: Set<String> = []
    private var pendingDeletedExpenses: [String: PendingDeletedExpenseContext] = [:]
    private var isLoadingNextPage: Bool = false

    init(
        categoryID: String,
        categoryName: String?,
        presenter: CategoryPresentationLogic,
        router: CategoryRoutingLogic,
        summaryProvider: CategorySummaryProviding,
        expensesProvider: CategoryExpensesProviding,
        pager: PagerLogic,
        expenseGrouping: MainExpenseGrouping
    ) {
        self.categoryID = categoryID
        self.categoryName = categoryName
        self.presenter = presenter
        self.router = router
        self.summaryProvider = summaryProvider
        self.expensesProvider = expensesProvider
        self.pager = pager
        self.expenseGrouping = expenseGrouping
    }

    func fetchData() async {
        pager.reset()

        loadingState = .loading
        category = nil
        expenses = []
        expenseGroups = []
        deletingExpenseIDs = []
        pendingDeletedExpenses = [:]
        isLoadingNextPage = false

        await presentFetchedData()
        await loadInitialData()
    }
}

private extension CategoryInteractor {
    func loadInitialData() async {
        guard let request = pager.beginNextPageIfPossible() else {
            loadingState = .loaded
            await presentFetchedData()
            return
        }

        do {
            async let categoryTask = summaryProvider.fetchCategory(id: categoryID)
            async let expensesTask = expensesProvider.fetchExpensesPage(
                categoryID: categoryID,
                cursor: request.cursor,
                limit: Constants.pageLimit
            )

            let loadedCategory = try await categoryTask
            let page = try await expensesTask

            category = loadedCategory
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

    func refreshSummaryAfterDeletionIfNeeded() async {
        do {
            category = try await summaryProvider.fetchCategory(id: categoryID)
        } catch {
            await router.presentError(with: L10n.mainOverviewError)
        }
    }

    func presentFetchedData() async {
        await presenter.presentFetchedData(
            CategoryFetchData(
                navigationTitle: currentNavigationTitle(),
                loadingState: loadingState,
                category: category,
                expenseGroups: expenseGroups,
                deletingExpenseIDs: deletingExpenseIDs,
                isLoadingNextPage: isLoadingNextPage,
                hasMore: pager.hasMorePages()
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
                categoryID: categoryID,
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

    func handleDeleteExpense(id: String) async {
        guard case .loaded = loadingState else {
            return
        }

        guard let removedIndex = expenses.firstIndex(where: { $0.id == id }) else {
            return
        }

        guard pendingDeletedExpenses[id] == nil else {
            return
        }

        let removedExpense = expenses.remove(at: removedIndex)
        pendingDeletedExpenses[id] = .init(
            expense: removedExpense,
            index: removedIndex
        )
        expenseGroups = expenseGrouping.groupExpenses(expenses)
        await presentFetchedData()

        do {
            try await expensesProvider.deleteExpense(id: id)
            pendingDeletedExpenses[id] = nil

            await refreshSummaryAfterDeletionIfNeeded()
            await presentFetchedData()
        } catch {
            if let pendingContext = pendingDeletedExpenses[id] {
                pendingDeletedExpenses[id] = nil
                let insertIndex = min(pendingContext.index, expenses.count)
                expenses.insert(pendingContext.expense, at: insertIndex)
                expenseGroups = expenseGrouping.groupExpenses(expenses)
            }

            await presentFetchedData()
            await router.presentError(with: L10n.mainOverviewError)
        }
    }

    func handleTapEditButton() async {
        await router.openCategoryEdit(
            id: categoryID,
            name: currentNavigationTitle()
        )
    }
}
