// Created by Egor Shkarin 23.03.2026

import Foundation

protocol MainBusinessLogic: Sendable {
    func fetchData() async
}

protocol MainHandler: AnyObject, Sendable {
    func handleTapSeeAllCategories() async
    func handleTapSeeAllExpenses() async
    func handleTapRetrySummary() async
    func handleTapRetryCategories() async
    func handleTapRetryExpenses() async
}

actor MainInteractor: MainBusinessLogic {
    private let presenter: MainPresentationLogic
    private let router: MainRoutingLogic
    private let summaryProvider: MainSummaryProviding
    private let categoriesProvider: MainCategoriesProviding
    private let expensesProvider: MainExpensesProviding
    private let expenseGrouping: MainExpenseGrouping

    private var summaryState: LoadingStatus = .idle
    private var categoriesState: LoadingStatus = .idle
    private var expensesState: LoadingStatus = .idle

    private var summary: MainSummaryModel?
    private var categories: [MainCategoryCardModel] = []
    private var expenseGroups: [MainExpenseGroupModel] = []

    init(
        presenter: MainPresentationLogic,
        router: MainRoutingLogic,
        summaryProvider: MainSummaryProviding,
        categoriesProvider: MainCategoriesProviding,
        expensesProvider: MainExpensesProviding,
        expenseGrouping: MainExpenseGrouping
    ) {
        self.presenter = presenter
        self.router = router
        self.summaryProvider = summaryProvider
        self.categoriesProvider = categoriesProvider
        self.expensesProvider = expensesProvider
        self.expenseGrouping = expenseGrouping
    }

    func fetchData() async {
        summaryState = .loading
        categoriesState = .loading
        expensesState = .loading

        summary = nil
        categories = []
        expenseGroups = []

        await presentFetchedData()

        async let summaryTask: Void = loadSummary()
        async let categoriesTask: Void = loadCategories()
        async let expensesTask: Void = loadExpenses()

        _ = await (summaryTask, categoriesTask, expensesTask)
    }
}

private extension MainInteractor {
    func loadSummary() async {
        do {
            summary = try await summaryProvider.fetchSummary()
            summaryState = .loaded
        } catch {
            summaryState = .failed(.undelinedError(description: error.localizedDescription))
        }

        await presentFetchedData()
    }

    func loadCategories() async {
        do {
            categories = try await categoriesProvider.fetchCategories()
            categoriesState = .loaded
        } catch {
            categoriesState = .failed(.undelinedError(description: error.localizedDescription))
        }

        await presentFetchedData()
    }

    func loadExpenses() async {
        do {
            let expenses = try await expensesProvider.fetchExpenses()
            expenseGroups = expenseGrouping.groupExpenses(expenses)
            expensesState = .loaded
        } catch {
            expensesState = .failed(.undelinedError(description: error.localizedDescription))
        }

        await presentFetchedData()
    }

    func presentFetchedData() async {
        await presenter.presentFetchedData(
            MainFetchData(
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
        await router.openAllCategories()
    }

    func handleTapSeeAllExpenses() async {
        await router.openAllExpenses()
    }

    func handleTapRetrySummary() async {
        summaryState = .loading
        summary = nil

        await presentFetchedData()
        await loadSummary()
    }

    func handleTapRetryCategories() async {
        categoriesState = .loading
        categories = []

        await presentFetchedData()
        await loadCategories()
    }

    func handleTapRetryExpenses() async {
        expensesState = .loading
        expenseGroups = []

        await presentFetchedData()
        await loadExpenses()
    }
}
