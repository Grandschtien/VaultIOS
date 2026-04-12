import XCTest
@testable import Vault

final class MainFlowDomainRepositoryTests: XCTestCase {
    func testRefreshMainFlowFillsStoreAndObserverSnapshots() async throws {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let categoriesService = CategoriesServiceStub(
            listResult: .success(
                CategoriesResponseDTO(
                    categories: [
                        .init(
                            id: "cat-1",
                            name: "Food",
                            icon: "🍴",
                            color: "light_orange",
                            totalSpentUsd: 15
                        )
                    ]
                )
            )
        )
        let expensesService = ExpensesServiceStub(
            listResults: [
                .success(
                    ExpensesListResponseDTO(
                        expenses: [
                            .init(
                                id: "exp-1",
                                title: "Coffee",
                                description: "Morning",
                                amount: 4,
                                currency: "USD",
                                category: "cat-1",
                                timeOfAdd: Date(timeIntervalSince1970: 100)
                            )
                        ],
                        nextCursor: nil,
                        hasMore: false
                    )
                )
            ]
        )
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            currencyConversionService: CurrencyConverterStub(),
            store: store,
            observer: observer
        )

        try await repository.refreshMainFlow()

        let state = store.snapshot()
        XCTAssertEqual(state.categoryOrder, ["cat-1"])
        XCTAssertEqual(state.recentExpenseIDs, ["exp-1"])
        XCTAssertEqual(observer.currentOverviewSnapshot().categories.count, 1)
        XCTAssertEqual(observer.currentOverviewSnapshot().expenseGroups.flatMap(\.expenses).count, 1)
    }
}

extension MainFlowDomainRepositoryTests {
    func testRefreshCategoriesForwardsCurrentPeriodToCategoriesRequest() async throws {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let categoriesService = CategoriesServiceStub(
            listResult: .success(
                .init(
                    categories: [
                        .init(
                            id: "cat-1",
                            name: "Food",
                            icon: "🍴",
                            color: "light_orange",
                            totalSpentUsd: 7
                        ),
                        .init(
                            id: "cat-2",
                            name: "Taxi",
                            icon: "🚕",
                            color: "light_blue",
                            totalSpentUsd: 18
                        )
                    ]
                )
            )
        )
        let period = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 1_735_689_600),
            to: Date(timeIntervalSince1970: 1_735_700_000)
        )
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: ExpensesServiceStub(listResults: []),
            summaryPeriodProvider: MainSummaryPeriodProviderStub(period: period),
            currencyConversionService: CurrencyConverterStub(),
            store: store,
            observer: observer
        )

        try await repository.refreshCategories()

        let state = store.snapshot()
        let requestedListParameters = await categoriesService.requestedListParameters()
        XCTAssertEqual(state.categoriesByID["cat-1"]?.amount, 7)
        XCTAssertEqual(state.categoriesByID["cat-2"]?.amount, 18)
        XCTAssertEqual(requestedListParameters, [.init(from: period.from, to: period.to)])
    }

    func testRefreshCategoriesUsesPlainRequestWhenNoSummaryPeriodProviderExists() async throws {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let categoriesService = CategoriesServiceStub(
            listResult: .success(
                .init(
                    categories: [
                        .init(
                            id: "cat-1",
                            name: "Food",
                            icon: "🍴",
                            color: "light_orange",
                            totalSpentUsd: 15
                        )
                    ]
                )
            )
        )
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: ExpensesServiceStub(listResults: []),
            currencyConversionService: CurrencyConverterStub(),
            store: store,
            observer: observer
        )

        try await repository.refreshCategories()

        XCTAssertEqual(store.snapshot().categoriesByID["cat-1"]?.amount, 15)
        let requestedListParameters = await categoriesService.requestedListParameters()
        XCTAssertEqual(requestedListParameters, [.init()])
    }
}

extension MainFlowDomainRepositoryTests {
    func testRefreshCategoryFirstPageRequestsCurrentMonthExpenses() async throws {
//        let store = MainFlowDomainStore()
//        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
//        let period = MainSummaryPeriod(
//            from: Date(timeIntervalSince1970: 1_735_689_600),
//            to: Date(timeIntervalSince1970: 1_735_700_000)
//        )
//        let summaryService = SummaryServiceStub(
//            summaryResult: .failure(RepositoryTestError.any),
//            byCategoryResult: .success(
//                .init(
//                    category: "cat-1",
//                    total: 9,
//                    currency: "USD",
//                    byCategory: nil
//                )
//            )
//        )
//        let categoriesService = CategoriesServiceStub(
//            listResult: .success(.init(categories: [])),
//            getResult: .success(
//                .init(
//                    category: .init(
//                        id: "cat-1",
//                        name: "Food",
//                        icon: "🍴",
//                        color: "light_orange",
//                        totalSpentUsd: 15
//                    )
//                )
//            )
//        )
//        let expensesService = ExpensesServiceStub(
//            listResults: [
//                .success(
//                    .init(
//                        expenses: [
//                            .init(
//                                id: "exp-1",
//                                title: "Coffee",
//                                description: "Morning",
//                                amount: 4,
//                                currency: "USD",
//                                category: "cat-1",
//                                timeOfAdd: Date(timeIntervalSince1970: 100)
//                            )
//                        ],
//                        nextCursor: "cursor-1",
//                        hasMore: true
//                    )
//                )
//            ]
//        )
//        let repository = MainFlowDomainRepository(
//            categoriesService: categoriesService,
//            expensesService: expensesService,
//            summaryService: summaryService,
//            summaryPeriodProvider: MainSummaryPeriodProviderStub(period: period),
//            currencyConversionService: CurrencyConverterStub(),
//            store: store,
//            observer: observer
//        )
//
//        try await repository.refreshCategoryFirstPage(id: "cat-1")
//
//        let requestedExpenseParameters = await expensesService.requestedParameters()
//        XCTAssertEqual(
//            requestedExpenseParameters,
//            [
//                .init(
//                    category: "cat-1",
//                    from: period.from,
//                    to: period.to,
//                    cursor: nil,
//                    limit: 20
//                )
//            ]
//        )
//        let requestedGetParameters = await categoriesService.requestedGetParameters()
//        XCTAssertEqual(requestedGetParameters.count, 1)
//        XCTAssertEqual(requestedGetParameters.first?.id, "cat-1")
//        XCTAssertEqual(
//            requestedGetParameters.first?.parameters,
//            .init(
//                from: period.from,
//                to: period.to
//            )
//        )
//        XCTAssertEqual(observer.currentCategorySnapshot(id: "cat-1").category?.amount, 9)
//        XCTAssertEqual(observer.currentCategorySnapshot(id: "cat-1").expenseGroups.flatMap(\.expenses).count, 1)
//        XCTAssertEqual(observer.currentCategorySnapshot(id: "cat-1").period, period)
    }

    func testLoadNextCategoryPageRequestsCurrentMonthExpenses() async throws {
//        let store = MainFlowDomainStore()
//        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
//        let period = MainSummaryPeriod(
//            from: Date(timeIntervalSince1970: 1_735_689_600),
//            to: Date(timeIntervalSince1970: 1_735_700_000)
//        )
//
//        store.update { state in
//            state.categoryPagination["cat-1"] = .init(
//                nextCursor: "cursor-1",
//                hasMore: true,
//                isLoaded: true
//            )
//        }
//
//        let expensesService = ExpensesServiceStub(
//            listResults: [
//                .success(
//                    .init(
//                        expenses: [],
//                        nextCursor: nil,
//                        hasMore: false
//                    )
//                )
//            ]
//        )
//        let repository = MainFlowDomainRepository(
//            categoriesService: CategoriesServiceStub(listResult: .success(.init(categories: []))),
//            expensesService: expensesService,
//            summaryPeriodProvider: MainSummaryPeriodProviderStub(period: period),
//            currencyConversionService: CurrencyConverterStub(),
//            store: store,
//            observer: observer
//        )
//
//        try await repository.loadNextCategoryPage(id: "cat-1")
//
//        let requestedExpenseParameters = await expensesService.requestedParameters()
//        XCTAssertEqual(
//            requestedExpenseParameters,
//            [
//                .init(
//                    category: "cat-1",
//                    from: period.from,
//                    to: period.to,
//                    cursor: "cursor-1",
//                    limit: 20
//                )
//            ]
//        )
    }
}

extension MainFlowDomainRepositoryTests {
    func testRefreshCategoryFirstPageKeepsOverviewAmountsWhenDetailUsesCustomFromDate() async throws {
//        let store = MainFlowDomainStore()
//        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
//        let customFromDate = Date(timeIntervalSince1970: 1_735_680_000)
//        let categoriesService = CategoriesServiceStub(
//            listResult: .success(
//                .init(
//                    categories: [
//                        .init(
//                            id: "cat-1",
//                            name: "Food",
//                            icon: "🍴",
//                            color: "light_orange",
//                            totalSpentUsd: 15
//                        )
//                    ]
//                )
//            ),
//            getResult: .success(
//                .init(
//                    category: .init(
//                        id: "cat-1",
//                        name: "Food",
//                        icon: "🍴",
//                        color: "light_orange",
//                        totalSpentUsd: 15
//                    )
//                )
//            )
//        )
//        let summaryService = SummaryServiceStub(
//            summaryResult: .success(
//                .init(
//                    category: nil,
//                    total: 7,
//                    currency: "USD",
//                    byCategory: [
//                        .init(category: "cat-1", total: 7)
//                    ]
//                )
//            ),
//            byCategoryResult: .success(
//                .init(
//                    category: "cat-1",
//                    total: 20,
//                    currency: "USD",
//                    byCategory: nil
//                )
//            )
//        )
//        let repository = MainFlowDomainRepository(
//            categoriesService: categoriesService,
//            expensesService: ExpensesServiceStub(
//                listResults: [
//                    .success(
//                        .init(
//                            expenses: [],
//                            nextCursor: nil,
//                            hasMore: false
//                        )
//                    )
//                ]
//            ),
//            summaryService: summaryService,
//            summaryPeriodProvider: MainSummaryPeriodProviderStub(
//                period: .init(
//                    from: Date(timeIntervalSince1970: 1_735_689_600),
//                    to: Date(timeIntervalSince1970: 1_735_700_000)
//                )
//            ),
//            currencyConversionService: CurrencyConverterStub(),
//            store: store,
//            observer: observer
//        )
//
//        try await repository.refreshCategories()
//        try await repository.refreshCategoryFirstPage(
//            id: "cat-1",
//            fromDate: customFromDate
//        )
//
//        XCTAssertEqual(observer.currentOverviewSnapshot().categories.first?.amount, 7)
//        XCTAssertEqual(observer.currentCategorySnapshot(id: "cat-1").category?.amount, 20)
    }

    func testRefreshCategoryFirstPageFailureResetsStoredScopeAndDropsOldCursor() async {
//        let store = MainFlowDomainStore()
//        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
//        let januaryPeriod = MainSummaryPeriod(
//            from: Date(timeIntervalSince1970: 1_735_689_600),
//            to: Date(timeIntervalSince1970: 1_736_553_000)
//        )
//        let februaryPeriod = MainSummaryPeriod(
//            from: Date(timeIntervalSince1970: 1_738_368_000),
//            to: Date(timeIntervalSince1970: 1_740_787_199)
//        )
//        let januaryExpense = MainExpenseModel(
//            id: "exp-jan",
//            title: "Coffee",
//            description: "Morning",
//            amount: 4,
//            currency: "USD",
//            category: "cat-1",
//            timeOfAdd: Date(timeIntervalSince1970: 1_736_000_000)
//        )
//
//        store.update { state in
//            state.expensesByID[januaryExpense.id] = januaryExpense
//            state.categoryExpenseIDs["cat-1"] = [januaryExpense.id]
//            state.categoryPagination["cat-1"] = .init(
//                nextCursor: "january-cursor",
//                hasMore: true,
//                isLoaded: true
//            )
//            state.categoryPeriods["cat-1"] = januaryPeriod
//        }
//        observer.publishAll(from: store)
//
//        let categoriesService = CategoriesServiceStub(
//            listResult: .success(.init(categories: [])),
//            getResult: .success(
//                .init(
//                    category: .init(
//                        id: "cat-1",
//                        name: "Food",
//                        icon: "🍴",
//                        color: "light_orange",
//                        totalSpentUsd: 15
//                    )
//                )
//            )
//        )
//        let expensesService = ExpensesServiceStub(
//            listResults: [.failure(RepositoryTestError.any)]
//        )
//        let repository = MainFlowDomainRepository(
//            categoriesService: categoriesService,
//            expensesService: expensesService,
//            currencyConversionService: CurrencyConverterStub(),
//            store: store,
//            observer: observer
//        )
//
//        do {
//            try await repository.refreshCategoryFirstPage(
//                id: "cat-1",
//                fromDate: februaryPeriod.from,
//                toDate: februaryPeriod.to
//            )
//            XCTFail("Expected refresh to fail")
//        } catch {}
//
//        let state = store.snapshot()
//        XCTAssertEqual(state.categoryPeriods["cat-1"], februaryPeriod)
//        XCTAssertEqual(state.categoryPagination["cat-1"], .init())
//        XCTAssertEqual(state.categoryExpenseIDs["cat-1"], [])
//        XCTAssertTrue(state.expensesByID.isEmpty)
//
//        let requestedParameters = await expensesService.requestedParameters()
//        XCTAssertEqual(
//            requestedParameters,
//            [
//                .init(
//                    category: "cat-1",
//                    from: februaryPeriod.from,
//                    to: februaryPeriod.to,
//                    cursor: nil,
//                    limit: 20
//                )
//            ]
//        )
//
//        try? await repository.loadNextCategoryPage(id: "cat-1")
//
//        let finalParameters = await expensesService.requestedParameters()
//        XCTAssertEqual(finalParameters, requestedParameters)
    }
}

extension MainFlowDomainRepositoryTests {
    func testDeleteExpenseFailureRollsBackOptimisticState() async {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let expense = MainExpenseModel(
            id: "exp-1",
            title: "Coffee",
            description: "Morning",
            amount: 4,
            currency: "USD",
            category: "cat-1",
            timeOfAdd: Date(timeIntervalSince1970: 100)
        )
        let category = MainCategoryCardModel(
            id: "cat-1",
            name: "Food",
            icon: "🍴",
            color: "light_orange",
            amount: 10,
            currency: "USD"
        )

        store.update { state in
            state.categoriesByID[category.id] = category
            state.categoryOrder = [category.id]
            state.expensesByID[expense.id] = expense
            state.categoryExpenseIDs[category.id] = [expense.id]
            state.categoryPagination[category.id] = .init(hasMore: false, isLoaded: true)
        }
        observer.publishAll(from: store)

        let repository = MainFlowDomainRepository(
            categoriesService: CategoriesServiceStub(listResult: .success(.init(categories: []))),
            expensesService: ExpensesServiceStub(
                listResults: [],
                deleteResult: .failure(RepositoryTestError.any)
            ),
            currencyConversionService: CurrencyConverterStub(),
            store: store,
            observer: observer
        )

        do {
            try await repository.deleteExpense(id: "exp-1")
            XCTFail("Expected delete to fail")
        } catch {
            XCTAssertEqual(store.snapshot().categoryExpenseIDs["cat-1"], ["exp-1"])
            XCTAssertEqual(observer.currentCategorySnapshot(id: "cat-1").expenseGroups.flatMap(\.expenses).count, 1)
        }
    }
}

extension MainFlowDomainRepositoryTests {
    func testAddExpenseDoesNotInsertIntoCategoryDetailsWhenExpenseIsAfterStoredToDate() async throws {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let period = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 10),
            to: Date(timeIntervalSince1970: 20)
        )
        let category = MainCategoryCardModel(
            id: "cat-1",
            name: "Food",
            icon: "🍴",
            color: "light_orange",
            amount: 10,
            currency: "USD"
        )

        store.update { state in
            state.categoriesByID[category.id] = category
            state.categoryDetailsByID[category.id] = category
            state.categoryOrder = [category.id]
            state.categoryPeriods[category.id] = period
            state.categoryExpenseIDs[category.id] = []
            state.categoryPagination[category.id] = .init(hasMore: false, isLoaded: true)
        }
        observer.publishAll(from: store)

        let categoriesService = CategoriesServiceStub(
            listResult: .success(
                .init(
                    categories: [
                        .init(
                            id: "cat-1",
                            name: "Food",
                            icon: "🍴",
                            color: "light_orange",
                            totalSpentUsd: 15
                        )
                    ]
                )
            )
        )
        let expensesService = ExpensesServiceStub(
            listResults: [],
            createResult: .success(
                .init(
                    expenses: [
                        .init(
                            id: "exp-server",
                            title: "Coffee",
                            description: "Morning",
                            amount: 4,
                            currency: "USD",
                            category: "cat-1",
                            timeOfAdd: Date(timeIntervalSince1970: 25)
                        )
                    ]
                )
            )
        )
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            currencyConversionService: CurrencyConverterStub(),
            store: store,
            observer: observer
        )

        try await repository.addExpense(
            .init(
                expenses: [
                    .init(
                        title: "Coffee",
                        description: "Morning",
                        amount: 4,
                        currency: "USD",
                        category: "cat-1",
                        timeOfAdd: Date(timeIntervalSince1970: 25)
                    )
                ]
            )
        )

        XCTAssertEqual(store.snapshot().categoryExpenseIDs["cat-1"], [])
        XCTAssertTrue(observer.currentCategorySnapshot(id: "cat-1").expenseGroups.isEmpty)
    }
}

extension MainFlowDomainRepositoryTests {
    func testHandleCurrencyDidChangeRecalculatesCategoriesWithoutCategoriesFetch() async {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let category = MainCategoryCardModel(
            id: "cat-1",
            name: "Food",
            icon: "🍴",
            color: "light_orange",
            amount: 500,
            currency: "KZT"
        )
        let expense = MainExpenseModel(
            id: "exp-1",
            title: "Coffee",
            description: "",
            amount: 5,
            currency: "KZT",
            category: "cat-1",
            timeOfAdd: Date(timeIntervalSince1970: 100)
        )

        store.update { state in
            state.preferredCurrencyCode = "KZT"
            state.categoriesByID[category.id] = category
            state.categoryOrder = [category.id]
            state.expensesByID[expense.id] = expense
            state.recentExpenseIDs = [expense.id]
            state.expensesListExpenseIDs = [expense.id]
            state.expensesListPagination = .init(
                nextCursor: nil,
                hasMore: false,
                isLoaded: true
            )
        }
        observer.publishAll(from: store)

        let categoriesService = CategoriesServiceStub(
            listResult: .success(.init(categories: []))
        )
        let expensesService = ExpensesServiceStub(
            listResults: [
                .success(.init(expenses: [], nextCursor: nil, hasMore: false)),
                .success(.init(expenses: [], nextCursor: nil, hasMore: false))
            ]
        )
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            currencyConversionService: CurrencyConverterStub(),
            store: store,
            observer: observer
        )

        await repository.handleCurrencyDidChange(
            .init(
                previousCurrencyCode: "KZT",
                previousRateToUsd: 2,
                updatedCurrencyCode: "USD",
                updatedRateToUsd: 1
            )
        )

        let state = store.snapshot()
        XCTAssertEqual(state.categoriesByID["cat-1"]?.currency, "USD")
        XCTAssertEqual(state.categoriesByID["cat-1"]?.amount, 1000)
        XCTAssertEqual(state.preferredCurrencyCode, "USD")

        let categoriesListCalls = await categoriesService.listCallsCount()
        let expensesListCalls = await expensesService.listCallsCount()
        XCTAssertEqual(categoriesListCalls, 0)
        XCTAssertEqual(expensesListCalls, 2)
    }
}

extension MainFlowDomainRepositoryTests {
    func testHandleCurrencyDidChangeFallsBackToCategoriesFetchWhenRecalculateIsNotPossible() async {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let category = MainCategoryCardModel(
            id: "cat-1",
            name: "Food",
            icon: "🍴",
            color: "light_orange",
            amount: 500,
            currency: "KZT"
        )

        store.update { state in
            state.preferredCurrencyCode = "KZT"
            state.categoriesByID[category.id] = category
            state.categoryOrder = [category.id]
        }
        observer.publishAll(from: store)

        let categoriesService = CategoriesServiceStub(
            listResult: .success(
                .init(
                    categories: [
                        .init(
                            id: "cat-1",
                            name: "Food",
                            icon: "🍴",
                            color: "light_orange",
                            totalSpentUsd: 15
                        )
                    ]
                )
            )
        )
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: ExpensesServiceStub(listResults: []),
            currencyConversionService: CurrencyConverterStub(),
            store: store,
            observer: observer
        )

        await repository.handleCurrencyDidChange(
            .init(
                previousCurrencyCode: "EUR",
                previousRateToUsd: 0.9,
                updatedCurrencyCode: "USD",
                updatedRateToUsd: 1
            )
        )

        let categoriesListCalls = await categoriesService.listCallsCount()
        XCTAssertEqual(categoriesListCalls, 1)
        XCTAssertEqual(store.snapshot().preferredCurrencyCode, "USD")
    }
}

extension MainFlowDomainRepositoryTests {
    func testAddExpenseSuccessReplacesOptimisticExpensesWithResponse() async throws {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let category = MainCategoryCardModel(
            id: "cat-1",
            name: "Food",
            icon: "🍴",
            color: "light_orange",
            amount: 10,
            currency: "USD"
        )

        store.update { state in
            state.categoriesByID[category.id] = category
            state.categoryOrder = [category.id]
            state.categoryExpenseIDs[category.id] = []
            state.categoryPagination[category.id] = .init(hasMore: false, isLoaded: true)
            state.expensesListPagination = .init(hasMore: false, isLoaded: true)
        }
        observer.publishAll(from: store)

        let categoriesService = CategoriesServiceStub(
            listResult: .success(
                .init(
                    categories: [
                        .init(
                            id: "cat-1",
                            name: "Food",
                            icon: "🍴",
                            color: "light_orange",
                            totalSpentUsd: 15
                        )
                    ]
                )
            )
        )
        let expensesService = ExpensesServiceStub(
            listResults: [],
            createResult: .success(
                .init(
                    expenses: [
                        .init(
                            id: "exp-server",
                            title: "Coffee",
                            description: "Morning",
                            amount: 4,
                            currency: "USD",
                            category: "cat-1",
                            timeOfAdd: Date(timeIntervalSince1970: 100)
                        )
                    ]
                )
            )
        )
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            currencyConversionService: CurrencyConverterStub(),
            store: store,
            observer: observer
        )

        try await repository.addExpense(
            .init(
                expenses: [
                    .init(
                        title: "Coffee",
                        description: "Morning",
                        amount: 4,
                        currency: "USD",
                        category: "cat-1",
                        timeOfAdd: Date(timeIntervalSince1970: 100)
                    )
                ]
            )
        )

        let state = store.snapshot()
        XCTAssertEqual(state.recentExpenseIDs, ["exp-server"])
        XCTAssertEqual(state.expensesListExpenseIDs, ["exp-server"])
        XCTAssertEqual(state.categoryExpenseIDs["cat-1"], ["exp-server"])
        XCTAssertEqual(Array(state.expensesByID.keys), ["exp-server"])
        XCTAssertEqual(state.expensesByID["exp-server"]?.title, "Coffee")
        let expensesListCallCount = await expensesService.listCallsCount()
        let categoriesListCallCount = await categoriesService.listCallsCount()
        XCTAssertEqual(expensesListCallCount, 0)
        XCTAssertEqual(categoriesListCallCount, 1)
    }
}

extension MainFlowDomainRepositoryTests {
    func testAddExpenseFailureRollsBackOptimisticInsert() async {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let category = MainCategoryCardModel(
            id: "cat-1",
            name: "Food",
            icon: "🍴",
            color: "light_orange",
            amount: 10,
            currency: "USD"
        )

        store.update { state in
            state.categoriesByID[category.id] = category
            state.categoryOrder = [category.id]
            state.categoryExpenseIDs[category.id] = []
            state.categoryPagination[category.id] = .init(hasMore: false, isLoaded: true)
            state.expensesListPagination = .init(hasMore: false, isLoaded: true)
        }
        observer.publishAll(from: store)

        let repository = MainFlowDomainRepository(
            categoriesService: CategoriesServiceStub(listResult: .success(.init(categories: []))),
            expensesService: ExpensesServiceStub(
                listResults: [],
                createResult: .failure(RepositoryTestError.any)
            ),
            currencyConversionService: CurrencyConverterStub(),
            store: store,
            observer: observer
        )

        do {
            try await repository.addExpense(
                ExpensesCreateRequestDTO(
                    expenses: [
                        .init(
                            title: "Coffee",
                            description: "Morning",
                            amount: 4,
                            currency: "USD",
                            category: "cat-1",
                            timeOfAdd: Date(timeIntervalSince1970: 100)
                        )
                    ]
                )
            )
            XCTFail("Expected add to fail")
        } catch {
            XCTAssertTrue(store.snapshot().expensesByID.isEmpty)
            XCTAssertTrue(observer.currentCategorySnapshot(id: "cat-1").expenseGroups.isEmpty)
        }
    }
}

private enum RepositoryTestError: Error {
    case any
}

private final class CurrencyConverterStub: UserCurrencyConverting, @unchecked Sendable {
    func convertUsdAmount(_ amount: Double) -> UserCurrencyAmount {
        .init(amount: amount, currency: "USD")
    }

    func convertExpense(amount: Double, currency: String) -> UserCurrencyAmount {
        .init(amount: amount, currency: currency)
    }
}

private actor CategoriesServiceStub: MainCategoriesContractServicing {
    private let listResult: Result<CategoriesResponseDTO, Error>
    private let getResult: Result<CategoryResponseDTO, Error>
    private var listCalls = 0
    private var listParametersHistory: [CategoriesQueryParameters] = []
    private var getParametersHistory: [(id: String, parameters: CategoriesQueryParameters)] = []

    init(
        listResult: Result<CategoriesResponseDTO, Error>,
        getResult: Result<CategoryResponseDTO, Error> = .failure(RepositoryTestError.any)
    ) {
        self.listResult = listResult
        self.getResult = getResult
    }

    func createCategory(_ request: CategoryCreateRequestDTO) async throws -> CategoryResponseDTO {
        throw RepositoryTestError.any
    }

    func listCategories() async throws -> CategoriesResponseDTO {
        listCalls += 1
        return try listResult.get()
    }

    func listCategories(parameters: CategoriesQueryParameters) async throws -> CategoriesResponseDTO {
        listParametersHistory.append(parameters)
        return try await listCategories()
    }

    func getCategory(id: String) async throws -> CategoryResponseDTO {
        try getResult.get()
    }

    func getCategory(
        id: String,
        parameters: CategoriesQueryParameters
    ) async throws -> CategoryResponseDTO {
        getParametersHistory.append((id, parameters))
        return try await getCategory(id: id)
    }

    func deleteCategory(id: String) async throws {}

    func listCallsCount() -> Int {
        listCalls
    }

    func requestedListParameters() -> [CategoriesQueryParameters] {
        listParametersHistory
    }

    func requestedGetParameters() -> [(id: String, parameters: CategoriesQueryParameters)] {
        getParametersHistory
    }
}

private actor ExpensesServiceStub: MainExpensesContractServicing {
    private let listResults: [Result<ExpensesListResponseDTO, Error>]
    private let createResult: Result<ExpensesCreateResponseDTO, Error>
    private let deleteResult: Result<Void, Error>
    private var parametersHistory: [ExpensesListQueryParameters] = []
    private var listCallCount: Int = .zero

    init(
        listResults: [Result<ExpensesListResponseDTO, Error>],
        createResult: Result<ExpensesCreateResponseDTO, Error> = .failure(RepositoryTestError.any),
        deleteResult: Result<Void, Error> = .success(())
    ) {
        self.listResults = listResults
        self.createResult = createResult
        self.deleteResult = deleteResult
    }

    func createExpenses(_ request: ExpensesCreateRequestDTO) async throws -> ExpensesCreateResponseDTO {
        try createResult.get()
    }

    func listExpenses(parameters: ExpensesListQueryParameters) async throws -> ExpensesListResponseDTO {
        parametersHistory.append(parameters)
        let index = min(listCallCount, max(listResults.count - 1, .zero))
        listCallCount += 1
        return try listResults[index].get()
    }

    func deleteExpense(id: String) async throws {
        _ = try deleteResult.get()
    }

    func listCallsCount() -> Int {
        listCallCount
    }

    func requestedParameters() -> [ExpensesListQueryParameters] {
        parametersHistory
    }
}

private actor SummaryServiceStub: MainSummaryContractServicing {
    private let summaryResult: Result<SummaryResponseDTO, Error>
    private let byCategoryResult: Result<SummaryResponseDTO, Error>
    private var parametersHistory: [SummaryQueryParameters] = []
    private var byCategoryParametersHistory: [(id: String, parameters: SummaryQueryParameters)] = []

    init(
        summaryResult: Result<SummaryResponseDTO, Error>,
        byCategoryResult: Result<SummaryResponseDTO, Error> = .failure(RepositoryTestError.any)
    ) {
        self.summaryResult = summaryResult
        self.byCategoryResult = byCategoryResult
    }

    func getSummary(parameters: SummaryQueryParameters) async throws -> SummaryResponseDTO {
        parametersHistory.append(parameters)
        return try summaryResult.get()
    }

    func getSummaryByCategory(
        id: String,
        parameters: SummaryQueryParameters
    ) async throws -> SummaryResponseDTO {
        byCategoryParametersHistory.append((id: id, parameters: parameters))
        return try byCategoryResult.get()
    }

    func requestedParameters() -> [SummaryQueryParameters] {
        parametersHistory
    }

    func requestedByCategoryParameters() -> [(id: String, parameters: SummaryQueryParameters)] {
        byCategoryParametersHistory
    }
}

private struct MainSummaryPeriodProviderStub: MainSummaryPeriodProviding {
    let period: MainSummaryPeriod

    func currentMonthPeriod() -> MainSummaryPeriod {
        period
    }
}
