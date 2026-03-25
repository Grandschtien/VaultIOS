// Created by Egor Shkarin 23.03.2026

import Foundation

protocol MainBusinessLogic: Sendable {
    func fetchData() async
}

protocol MainHandler: AnyObject, Sendable {
    func handleTapSeeAllCategories() async
    func handleTapSeeAllExpenses() async
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
    private let categoriesProvider: MainCategoriesProviding
    private let expensesProvider: MainExpensesProviding
    private let expenseGrouping: MainExpenseGrouping

    private var blockingErrorDescription: String?
    private var summaryState: LoadingStatus = .idle
    private var categoriesState: LoadingStatus = .idle
    private var expensesState: LoadingStatus = .idle

    private var summary: MainSummaryModel?
    private var categories: [MainCategoryCardModel] = []
    private var expenseGroups: [MainExpenseGroupModel] = []

    init(
        presenter: MainPresentationLogic,
        router: MainRoutingLogic,
        currencyRateProvider: MainCurrencyRateProviding,
        summaryProvider: MainSummaryProviding,
        categoriesProvider: MainCategoriesProviding,
        expensesProvider: MainExpensesProviding,
        expenseGrouping: MainExpenseGrouping
    ) {
        self.presenter = presenter
        self.router = router
        self.currencyRateProvider = currencyRateProvider
        self.summaryProvider = summaryProvider
        self.categoriesProvider = categoriesProvider
        self.expensesProvider = expensesProvider
        self.expenseGrouping = expenseGrouping
    }

    func fetchData() async {
        guard await validateLaunchCurrencyRate() else {
            return
        }

        await loadMainData()
    }
}

private extension MainInteractor {
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
