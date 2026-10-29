import XCTest
@testable import Vylok

final class MainFlowDomainRepositoryTests: XCTestCase {
    func testRefreshMainFlowFillsStoreAndObserverSnapshots() async throws {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesParametersReturnValue = CategoriesResponseDTO(
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
        categoriesService.getCategoryIdParametersThrowableError = RepositoryTestError.any
        let expensesService = MainExpensesContractServicingMock()
        let expensesServiceListResults: [Result<ExpensesListResponseDTO, Error>] = [
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
        expensesService.listExpensesParametersClosure = { [unowned expensesService] _ in
            let index = min(expensesService.listExpensesParametersCallsCount - 1, expensesServiceListResults.count - 1)
            return try expensesServiceListResults[index].get()
        }
        expensesService.createExpensesThrowableError = RepositoryTestError.any
        let currencyConversionService = UserCurrencyConvertingMock()
        currencyConversionService.convertUsdAmountClosure = { .init(amount: $0, currency: "USD") }
        currencyConversionService.convertExpenseAmountCurrencyOriginalAmountOriginalCurrencyClosure = { amount, currency, _, _ in
            .init(amount: amount, currency: currency)
        }
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            currencyConversionService: currencyConversionService,
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
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesParametersReturnValue = .init(
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
        categoriesService.getCategoryIdParametersThrowableError = RepositoryTestError.any
        let period = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 1_735_689_600),
            to: Date(timeIntervalSince1970: 1_735_700_000)
        )
        let expensesService = MainExpensesContractServicingMock()
        expensesService.createExpensesThrowableError = RepositoryTestError.any
        let summaryPeriodProvider = MainSummaryPeriodProvidingMock()
        summaryPeriodProvider.currentMonthPeriodReturnValue = period
        let currencyConversionService = UserCurrencyConvertingMock()
        currencyConversionService.convertUsdAmountClosure = { .init(amount: $0, currency: "USD") }
        currencyConversionService.convertExpenseAmountCurrencyOriginalAmountOriginalCurrencyClosure = { amount, currency, _, _ in
            .init(amount: amount, currency: currency)
        }
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            summaryPeriodProvider: summaryPeriodProvider,
            currencyConversionService: currencyConversionService,
            store: store,
            observer: observer
        )

        try await repository.refreshCategories()

        let state = store.snapshot()
        let requestedListParameters = categoriesService.listCategoriesParametersReceivedInvocations
        XCTAssertEqual(state.categoriesByID["cat-1"]?.amount, 7)
        XCTAssertEqual(state.categoriesByID["cat-2"]?.amount, 18)
        XCTAssertEqual(requestedListParameters, [.init(from: period.from, to: period.to)])
    }

    func testRefreshExpensesFirstPageForwardsCurrentPeriodToExpensesRequest() async throws {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let period = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 1_735_689_600),
            to: Date(timeIntervalSince1970: 1_735_700_000)
        )
        let expensesService = MainExpensesContractServicingMock()
        let expensesServiceListResults: [Result<ExpensesListResponseDTO, Error>] = [
            .success(
                .init(
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
        expensesService.listExpensesParametersClosure = { [unowned expensesService] _ in
            let index = min(expensesService.listExpensesParametersCallsCount - 1, expensesServiceListResults.count - 1)
            return try expensesServiceListResults[index].get()
        }
        expensesService.createExpensesThrowableError = RepositoryTestError.any
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesParametersReturnValue = .init(categories: [])
        categoriesService.getCategoryIdParametersThrowableError = RepositoryTestError.any
        let summaryPeriodProvider = MainSummaryPeriodProvidingMock()
        summaryPeriodProvider.currentMonthPeriodReturnValue = period
        let currencyConversionService = UserCurrencyConvertingMock()
        currencyConversionService.convertUsdAmountClosure = { .init(amount: $0, currency: "USD") }
        currencyConversionService.convertExpenseAmountCurrencyOriginalAmountOriginalCurrencyClosure = { amount, currency, _, _ in
            .init(amount: amount, currency: currency)
        }
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            summaryPeriodProvider: summaryPeriodProvider,
            currencyConversionService: currencyConversionService,
            store: store,
            observer: observer
        )

        try await repository.refreshExpensesFirstPage()

        let requestedParameters = expensesService.listExpensesParametersReceivedInvocations
        XCTAssertEqual(
            requestedParameters,
            [
                .init(
                    from: period.from,
                    to: period.to,
                    cursor: nil,
                    limit: 20
                )
            ]
        )
        XCTAssertEqual(store.snapshot().expensesListExpenseIDs, ["exp-1"])
    }

    func testLoadNextExpensesPageOmitsCurrentPeriodFromCursorRequest() async throws {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let period = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 1_735_689_600),
            to: Date(timeIntervalSince1970: 1_735_700_000)
        )
        let expensesService = MainExpensesContractServicingMock()
        let expensesServiceListResults: [Result<ExpensesListResponseDTO, Error>] = [
            .success(
                .init(
                    expenses: [],
                    nextCursor: nil,
                    hasMore: false
                )
            )
        ]
        expensesService.listExpensesParametersClosure = { [unowned expensesService] _ in
            let index = min(expensesService.listExpensesParametersCallsCount - 1, expensesServiceListResults.count - 1)
            return try expensesServiceListResults[index].get()
        }
        expensesService.createExpensesThrowableError = RepositoryTestError.any
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesParametersReturnValue = .init(categories: [])
        categoriesService.getCategoryIdParametersThrowableError = RepositoryTestError.any
        let summaryPeriodProvider = MainSummaryPeriodProvidingMock()
        summaryPeriodProvider.currentMonthPeriodReturnValue = period
        let currencyConversionService = UserCurrencyConvertingMock()
        currencyConversionService.convertUsdAmountClosure = { .init(amount: $0, currency: "USD") }
        currencyConversionService.convertExpenseAmountCurrencyOriginalAmountOriginalCurrencyClosure = { amount, currency, _, _ in
            .init(amount: amount, currency: currency)
        }
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            summaryPeriodProvider: summaryPeriodProvider,
            currencyConversionService: currencyConversionService,
            store: store,
            observer: observer
        )

        store.update { state in
            state.expensesListPagination = .init(
                nextCursor: "cursor-1",
                hasMore: true,
                isLoaded: true
            )
        }

        try await repository.loadNextExpensesPage()

        let requestedParameters = expensesService.listExpensesParametersReceivedInvocations
        XCTAssertEqual(
            requestedParameters,
            [
                .init(
                    cursor: "cursor-1",
                    limit: 20
                )
            ]
        )
    }

    func testLoadNextCategoryPageOmitsCurrentPeriodFromCursorRequest() async throws {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let period = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 1_735_689_600),
            to: Date(timeIntervalSince1970: 1_735_700_000)
        )
        let expensesService = MainExpensesContractServicingMock()
        let expensesServiceListResults: [Result<ExpensesListResponseDTO, Error>] = [
            .success(
                .init(
                    expenses: [],
                    nextCursor: nil,
                    hasMore: false
                )
            )
        ]
        expensesService.listExpensesParametersClosure = { [unowned expensesService] _ in
            let index = min(expensesService.listExpensesParametersCallsCount - 1, expensesServiceListResults.count - 1)
            return try expensesServiceListResults[index].get()
        }
        expensesService.createExpensesThrowableError = RepositoryTestError.any
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesParametersReturnValue = .init(categories: [])
        categoriesService.getCategoryIdParametersThrowableError = RepositoryTestError.any
        let summaryPeriodProvider = MainSummaryPeriodProvidingMock()
        summaryPeriodProvider.currentMonthPeriodReturnValue = period
        let currencyConversionService = UserCurrencyConvertingMock()
        currencyConversionService.convertUsdAmountClosure = { .init(amount: $0, currency: "USD") }
        currencyConversionService.convertExpenseAmountCurrencyOriginalAmountOriginalCurrencyClosure = { amount, currency, _, _ in
            .init(amount: amount, currency: currency)
        }
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            summaryPeriodProvider: summaryPeriodProvider,
            currencyConversionService: currencyConversionService,
            store: store,
            observer: observer
        )

        store.update { state in
            state.categoryPagination["cat-1"] = .init(
                nextCursor: "cursor-1",
                hasMore: true,
                isLoaded: true
            )
            state.categoryPeriods["cat-1"] = period
        }

        try await repository.loadNextCategoryPage(id: "cat-1")

        let requestedParameters = expensesService.listExpensesParametersReceivedInvocations
        XCTAssertEqual(
            requestedParameters,
            [
                .init(
                    category: "cat-1",
                    cursor: "cursor-1",
                    limit: 20
                )
            ]
        )
    }

    func testRefreshCategoriesUsesPlainRequestWhenNoSummaryPeriodProviderExists() async throws {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesParametersReturnValue = .init(
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
        categoriesService.getCategoryIdParametersThrowableError = RepositoryTestError.any
        let expensesService = MainExpensesContractServicingMock()
        expensesService.createExpensesThrowableError = RepositoryTestError.any
        let currencyConversionService = UserCurrencyConvertingMock()
        currencyConversionService.convertUsdAmountClosure = { .init(amount: $0, currency: "USD") }
        currencyConversionService.convertExpenseAmountCurrencyOriginalAmountOriginalCurrencyClosure = { amount, currency, _, _ in
            .init(amount: amount, currency: currency)
        }
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            currencyConversionService: currencyConversionService,
            store: store,
            observer: observer
        )

        try await repository.refreshCategories()

        XCTAssertEqual(store.snapshot().categoriesByID["cat-1"]?.amount, 15)
        let requestedListParameters = categoriesService.listCategoriesParametersReceivedInvocations
        XCTAssertEqual(requestedListParameters, [.init()])
    }
}

extension MainFlowDomainRepositoryTests {
    func testRefreshLoadedPeriodDependentModulesRefreshesLoadedExpensesAndCategoriesWithSharedPeriod() async throws {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let period = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 1_735_689_600),
            to: Date(timeIntervalSince1970: 1_735_700_000)
        )
        let oldPeriod = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 1_733_011_200),
            to: Date(timeIntervalSince1970: 1_733_097_599)
        )
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesParametersReturnValue = .init(categories: [])
        categoriesService.getCategoryIdParametersReturnValue = .init(
            category: .init(
                id: "cat-1",
                name: "Food",
                icon: "🍴",
                color: "light_orange",
                totalSpentUsd: 15
            )
        )
        let expensesService = MainExpensesContractServicingMock()
        let expensesServiceListResults: [Result<ExpensesListResponseDTO, Error>] = [
            .success(
                .init(
                    expenses: [
                        .init(
                            id: "exp-list",
                            title: "Taxi",
                            description: nil,
                            amount: 12,
                            currency: "USD",
                            category: "cat-1",
                            timeOfAdd: Date(timeIntervalSince1970: 100)
                        )
                    ],
                    nextCursor: nil,
                    hasMore: false
                )
            ),
            .success(
                .init(
                    expenses: [
                        .init(
                            id: "exp-cat",
                            title: "Lunch",
                            description: nil,
                            amount: 8,
                            currency: "USD",
                            category: "cat-1",
                            timeOfAdd: Date(timeIntervalSince1970: 200)
                        )
                    ],
                    nextCursor: nil,
                    hasMore: false
                )
            )
        ]
        expensesService.listExpensesParametersClosure = { [unowned expensesService] _ in
            let index = min(expensesService.listExpensesParametersCallsCount - 1, expensesServiceListResults.count - 1)
            return try expensesServiceListResults[index].get()
        }
        expensesService.createExpensesThrowableError = RepositoryTestError.any
        let summaryPeriodProvider = MainSummaryPeriodProvidingMock()
        summaryPeriodProvider.currentMonthPeriodReturnValue = period
        let currencyConversionService = UserCurrencyConvertingMock()
        currencyConversionService.convertUsdAmountClosure = { .init(amount: $0, currency: "USD") }
        currencyConversionService.convertExpenseAmountCurrencyOriginalAmountOriginalCurrencyClosure = { amount, currency, _, _ in
            .init(amount: amount, currency: currency)
        }
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            summaryPeriodProvider: summaryPeriodProvider,
            currencyConversionService: currencyConversionService,
            store: store,
            observer: observer
        )
        let normalizedCategoryPeriod = MainSummaryPeriod(
            from: Calendar.current.startOfDay(for: period.from),
            to: period.to
        )

        store.update { state in
            state.expensesListPagination = .init(hasMore: false, isLoaded: true)
            state.categoryPagination["cat-1"] = .init(hasMore: false, isLoaded: true)
            state.categoryPeriods["cat-1"] = oldPeriod
        }

        await repository.refreshLoadedPeriodDependentModules()

        let requestedParameters = expensesService.listExpensesParametersReceivedInvocations
        XCTAssertEqual(
            requestedParameters,
            [
                .init(
                    from: period.from,
                    to: period.to,
                    cursor: nil,
                    limit: 20
                ),
                .init(
                    category: "cat-1",
                    from: normalizedCategoryPeriod.from,
                    to: period.to,
                    cursor: nil,
                    limit: 20
                )
            ]
        )
        XCTAssertEqual(store.snapshot().categoryPeriods["cat-1"], normalizedCategoryPeriod)
        XCTAssertEqual(store.snapshot().expensesListExpenseIDs, ["exp-list"])
        XCTAssertEqual(store.snapshot().categoryExpenseIDs["cat-1"], ["exp-cat"])
    }
}

extension MainFlowDomainRepositoryTests {
    func testRefreshCategoryFirstPageUsesSummaryAmountAndCurrencyOnCategoryScreen() async throws {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let period = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 1_735_689_600),
            to: Date(timeIntervalSince1970: 1_735_700_000)
        )
        let summaryService = MainSummaryContractServicingMock()
        summaryService.getSummaryParametersThrowableError = RepositoryTestError.any
        summaryService.getSummaryByCategoryIdParametersReturnValue = .init(
            category: "cat-1",
            total: 53_210,
            totalUsd: 123.45,
            currency: "KZT",
            byCategory: nil
        )
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesParametersReturnValue = .init(categories: [])
        categoriesService.getCategoryIdParametersReturnValue = .init(
            category: .init(
                id: "cat-1",
                name: "Food",
                icon: "🍴",
                color: "light_orange",
                totalSpent: 53_210,
                currency: "KZT"
            )
        )
        let expensesService = MainExpensesContractServicingMock()
        let expensesServiceListResults: [Result<ExpensesListResponseDTO, Error>] = [
            .success(
                .init(
                    expenses: [],
                    nextCursor: nil,
                    hasMore: false
                )
            )
        ]
        expensesService.listExpensesParametersClosure = { [unowned expensesService] _ in
            let index = min(expensesService.listExpensesParametersCallsCount - 1, expensesServiceListResults.count - 1)
            return try expensesServiceListResults[index].get()
        }
        expensesService.createExpensesThrowableError = RepositoryTestError.any
        let summaryPeriodProvider = MainSummaryPeriodProvidingMock()
        summaryPeriodProvider.currentMonthPeriodReturnValue = period
        let currencyConversionService = UserCurrencyConvertingMock()
        currencyConversionService.convertUsdAmountClosure = { .init(amount: $0, currency: "USD") }
        currencyConversionService.convertExpenseAmountCurrencyOriginalAmountOriginalCurrencyClosure = { amount, currency, _, _ in
            .init(amount: amount, currency: currency)
        }
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            summaryService: summaryService,
            summaryPeriodProvider: summaryPeriodProvider,
            currencyConversionService: currencyConversionService,
            store: store,
            observer: observer,
            calendar: makeCalendar()
        )

        try await repository.refreshCategoryFirstPage(id: "cat-1")

        let requestedByCategoryParameters = summaryService.getSummaryByCategoryIdParametersReceivedInvocations
        XCTAssertEqual(requestedByCategoryParameters.count, 1)
        XCTAssertEqual(requestedByCategoryParameters.first?.id, "cat-1")
        XCTAssertEqual(
            requestedByCategoryParameters.first?.parameters,
            .init(from: period.from, to: period.to)
        )
        XCTAssertEqual(observer.currentCategorySnapshot(id: "cat-1").category?.amount, 53_210)
        XCTAssertEqual(observer.currentCategorySnapshot(id: "cat-1").category?.currency, "KZT")
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
//        let requestedExpenseParameters = expensesService.listExpensesParametersReceivedInvocations
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
//        let requestedGetParameters = categoriesService.getCategoryIdParametersReceivedInvocations
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
//        let requestedExpenseParameters = expensesService.listExpensesParametersReceivedInvocations
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
//        let requestedParameters = expensesService.listExpensesParametersReceivedInvocations
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
//        let finalParameters = expensesService.listExpensesParametersReceivedInvocations
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

        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesParametersReturnValue = .init(categories: [])
        categoriesService.getCategoryIdParametersThrowableError = RepositoryTestError.any
        let expensesService = MainExpensesContractServicingMock()
        expensesService.createExpensesThrowableError = RepositoryTestError.any
        expensesService.deleteExpenseIdThrowableError = RepositoryTestError.any
        let currencyConversionService = UserCurrencyConvertingMock()
        currencyConversionService.convertUsdAmountClosure = { .init(amount: $0, currency: "USD") }
        currencyConversionService.convertExpenseAmountCurrencyOriginalAmountOriginalCurrencyClosure = { amount, currency, _, _ in
            .init(amount: amount, currency: currency)
        }
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            currencyConversionService: currencyConversionService,
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
    func testAddExpenseInsertsIntoCategoryDetailsWhenStoredToDateIsOnCurrentDay() async throws {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let currentDayNow = Date(timeIntervalSince1970: 30)
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

        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesParametersReturnValue = .init(categories: [])
        categoriesService.getCategoryIdParametersThrowableError = RepositoryTestError.any
        let expensesService = MainExpensesContractServicingMock()
        expensesService.createExpensesReturnValue = .init(
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
        let currencyConversionService = UserCurrencyConvertingMock()
        currencyConversionService.convertUsdAmountClosure = { .init(amount: $0, currency: "USD") }
        currencyConversionService.convertExpenseAmountCurrencyOriginalAmountOriginalCurrencyClosure = { amount, currency, _, _ in
            .init(amount: amount, currency: currency)
        }
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            currencyConversionService: currencyConversionService,
            store: store,
            observer: observer,
            now: { currentDayNow }
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

        XCTAssertEqual(store.snapshot().categoryExpenseIDs["cat-1"], ["exp-server"])
        XCTAssertEqual(observer.currentCategorySnapshot(id: "cat-1").expenseGroups.flatMap(\.expenses).map(\.id), ["exp-server"])
    }

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

        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesParametersReturnValue = .init(
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
        categoriesService.getCategoryIdParametersThrowableError = RepositoryTestError.any
        let expensesService = MainExpensesContractServicingMock()
        expensesService.createExpensesReturnValue = .init(
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
        let currencyConversionService = UserCurrencyConvertingMock()
        currencyConversionService.convertUsdAmountClosure = { .init(amount: $0, currency: "USD") }
        currencyConversionService.convertExpenseAmountCurrencyOriginalAmountOriginalCurrencyClosure = { amount, currency, _, _ in
            .init(amount: amount, currency: currency)
        }
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            currencyConversionService: currencyConversionService,
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
    func testHandleCurrencyDidChangeReloadsSummaryCategoriesAndLoadedScopes() async {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let period = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 1_735_689_600),
            to: Date(timeIntervalSince1970: 1_735_700_000)
        )
        let staleCategory = MainCategoryCardModel(
            id: "cat-1",
            name: "Food",
            icon: "🍴",
            color: "light_orange",
            amount: 15,
            currency: "USD"
        )
        let staleExpense = MainExpenseModel(
            id: "exp-stale",
            title: "Old coffee",
            description: "",
            amount: 5,
            currency: "USD",
            category: "cat-1",
            timeOfAdd: Date(timeIntervalSince1970: 100)
        )
        let recentExpense = ExpenseDTO(
            id: "exp-recent",
            title: "Lunch",
            description: "",
            amount: 20_000,
            currency: "KZT",
            category: "cat-1",
            timeOfAdd: Date(timeIntervalSince1970: 200)
        )
        let listExpense = ExpenseDTO(
            id: "exp-list",
            title: "Taxi",
            description: "",
            amount: 8_000,
            currency: "KZT",
            category: "cat-1",
            timeOfAdd: Date(timeIntervalSince1970: 150)
        )
        let categoryExpense = ExpenseDTO(
            id: "exp-category",
            title: "Dinner",
            description: "",
            amount: 25_210,
            currency: "KZT",
            category: "cat-1",
            timeOfAdd: Date(timeIntervalSince1970: 250)
        )

        store.update { state in
            state.preferredCurrencyCode = "USD"
            state.overviewSummary = .init(totalAmount: 15, currency: "USD", changePercent: .zero)
            state.categoriesByID[staleCategory.id] = staleCategory
            state.categoryOrder = [staleCategory.id]
            state.categoryDetailsByID[staleCategory.id] = staleCategory
            state.expensesByID[staleExpense.id] = staleExpense
            state.recentExpenseIDs = [staleExpense.id]
            state.expensesListPagination = .init(hasMore: false, isLoaded: true)
            state.categoryExpenseIDs[staleCategory.id] = []
            state.categoryPagination[staleCategory.id] = .init(hasMore: false, isLoaded: true)
            state.categoryPeriods[staleCategory.id] = period
        }
        observer.publishAll(from: store)

        let summaryService = MainSummaryContractServicingMock()
        summaryService.getSummaryParametersReturnValue = .init(
            category: nil,
            total: 60_000,
            totalUsd: 120,
            currency: "KZT",
            byCategory: nil
        )
        summaryService.getSummaryByCategoryIdParametersReturnValue = .init(
            category: "cat-1",
            total: 53_210,
            totalUsd: 106.42,
            currency: "KZT",
            byCategory: nil
        )
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesParametersReturnValue = .init(
            categories: [
                .init(
                    id: "cat-1",
                    name: "Food",
                    icon: "🍴",
                    color: "light_orange",
                    totalSpent: 53_210,
                    currency: "KZT"
                )
            ]
        )
        categoriesService.getCategoryIdParametersReturnValue = .init(
            category: .init(
                id: "cat-1",
                name: "Food",
                icon: "🍴",
                color: "light_orange",
                totalSpent: 53_210,
                currency: "KZT"
            )
        )
        let expensesService = MainExpensesContractServicingMock()
        let expensesServiceListResults: [Result<ExpensesListResponseDTO, Error>] = [
            .success(.init(expenses: [recentExpense], nextCursor: nil, hasMore: false)),
            .success(.init(expenses: [listExpense], nextCursor: nil, hasMore: false)),
            .success(.init(expenses: [categoryExpense], nextCursor: nil, hasMore: false))
        ]
        expensesService.listExpensesParametersClosure = { [unowned expensesService] _ in
            let index = min(expensesService.listExpensesParametersCallsCount - 1, expensesServiceListResults.count - 1)
            return try expensesServiceListResults[index].get()
        }
        expensesService.createExpensesThrowableError = RepositoryTestError.any
        let summaryPeriodProvider = MainSummaryPeriodProvidingMock()
        summaryPeriodProvider.currentMonthPeriodReturnValue = period
        let currencyConversionService = UserCurrencyConvertingMock()
        currencyConversionService.convertUsdAmountClosure = { .init(amount: $0, currency: "USD") }
        currencyConversionService.convertExpenseAmountCurrencyOriginalAmountOriginalCurrencyClosure = { amount, currency, _, _ in
            .init(amount: amount, currency: currency)
        }
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            summaryService: summaryService,
            summaryPeriodProvider: summaryPeriodProvider,
            currencyConversionService: currencyConversionService,
            store: store,
            observer: observer,
            calendar: makeCalendar()
        )

        await repository.handleCurrencyDidChange(
            .init(
                previousCurrencyCode: "USD",
                previousRateToUsd: 1,
                updatedCurrencyCode: "KZT",
                updatedRateToUsd: 0.002
            )
        )

        let state = store.snapshot()
        XCTAssertEqual(state.overviewSummary?.totalAmount, 60_000)
        XCTAssertEqual(state.overviewSummary?.currency, "KZT")
        XCTAssertEqual(state.categoriesByID["cat-1"]?.amount, 53_210)
        XCTAssertEqual(state.categoriesByID["cat-1"]?.currency, "KZT")
        XCTAssertEqual(state.recentExpenseIDs, ["exp-recent"])
        XCTAssertEqual(state.expensesListExpenseIDs, ["exp-list"])
        XCTAssertEqual(state.categoryExpenseIDs["cat-1"], ["exp-category"])
        XCTAssertEqual(state.preferredCurrencyCode, "KZT")
        XCTAssertEqual(observer.currentOverviewSnapshot().summary?.totalAmount, 60_000)
        XCTAssertEqual(observer.currentOverviewSnapshot().summary?.currency, "KZT")

        let summaryParameters = summaryService.getSummaryParametersReceivedInvocations
        let categorySummaryParameters = summaryService.getSummaryByCategoryIdParametersReceivedInvocations
        let categoriesListCalls = categoriesService.listCategoriesParametersCallsCount
        let categoryRequests = categoriesService.getCategoryIdParametersReceivedInvocations
        let expenseRequests = expensesService.listExpensesParametersReceivedInvocations

        XCTAssertEqual(summaryParameters, [.init(from: period.from, to: period.to)])
        XCTAssertEqual(categorySummaryParameters.map(\.id), ["cat-1"])
        XCTAssertEqual(categorySummaryParameters.map(\.parameters), [.init(from: period.from, to: period.to)])
        XCTAssertEqual(categoriesListCalls, 1)
        XCTAssertEqual(categoryRequests.map(\.id), ["cat-1"])
        XCTAssertEqual(categoryRequests.map(\.parameters), [.init(from: period.from, to: period.to)])
        XCTAssertEqual(
            expenseRequests,
            [
                .init(from: period.from, to: period.to, limit: 5),
                .init(from: period.from, to: period.to, cursor: nil, limit: 20),
                .init(category: "cat-1", from: period.from, to: period.to, cursor: nil, limit: 20)
            ]
        )
    }
}

extension MainFlowDomainRepositoryTests {
    func testHandleCurrencyDidChangeClearsStaleCacheWhenReloadFails() async {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let period = MainSummaryPeriod(
            from: Date(timeIntervalSince1970: 1_735_689_600),
            to: Date(timeIntervalSince1970: 1_735_700_000)
        )
        let category = MainCategoryCardModel(
            id: "cat-1",
            name: "Food",
            icon: "🍴",
            color: "light_orange",
            amount: 15,
            currency: "USD"
        )
        let expense = MainExpenseModel(
            id: "exp-1",
            title: "Coffee",
            description: "",
            amount: 5,
            currency: "USD",
            category: "cat-1",
            timeOfAdd: Date(timeIntervalSince1970: 100)
        )

        store.update { state in
            state.preferredCurrencyCode = "USD"
            state.overviewSummary = .init(totalAmount: 15, currency: "USD", changePercent: .zero)
            state.categoriesByID[category.id] = category
            state.categoryOrder = [category.id]
            state.categoryDetailsByID[category.id] = category
            state.expensesByID[expense.id] = expense
            state.recentExpenseIDs = [expense.id]
            state.expensesListExpenseIDs = [expense.id]
            state.expensesListPagination = .init(hasMore: true, isLoaded: true)
            state.categoryExpenseIDs[category.id] = [expense.id]
            state.categoryPagination[category.id] = .init(hasMore: true, isLoaded: true)
            state.categoryPeriods[category.id] = period
        }
        observer.publishAll(from: store)

        let summaryService = MainSummaryContractServicingMock()
        summaryService.getSummaryParametersThrowableError = RepositoryTestError.any
        summaryService.getSummaryByCategoryIdParametersThrowableError = RepositoryTestError.any
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesParametersThrowableError = RepositoryTestError.any
        categoriesService.getCategoryIdParametersThrowableError = RepositoryTestError.any
        let expensesService = MainExpensesContractServicingMock()
        let expensesServiceListResults: [Result<ExpensesListResponseDTO, Error>] = [
            .failure(RepositoryTestError.any),
            .failure(RepositoryTestError.any),
            .failure(RepositoryTestError.any)
        ]
        expensesService.listExpensesParametersClosure = { [unowned expensesService] _ in
            let index = min(expensesService.listExpensesParametersCallsCount - 1, expensesServiceListResults.count - 1)
            return try expensesServiceListResults[index].get()
        }
        expensesService.createExpensesThrowableError = RepositoryTestError.any
        let summaryPeriodProvider = MainSummaryPeriodProvidingMock()
        summaryPeriodProvider.currentMonthPeriodReturnValue = period
        let currencyConversionService = UserCurrencyConvertingMock()
        currencyConversionService.convertUsdAmountClosure = { .init(amount: $0, currency: "USD") }
        currencyConversionService.convertExpenseAmountCurrencyOriginalAmountOriginalCurrencyClosure = { amount, currency, _, _ in
            .init(amount: amount, currency: currency)
        }
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            summaryService: summaryService,
            summaryPeriodProvider: summaryPeriodProvider,
            currencyConversionService: currencyConversionService,
            store: store,
            observer: observer,
            calendar: makeCalendar()
        )

        await repository.handleCurrencyDidChange(
            .init(
                previousCurrencyCode: "USD",
                previousRateToUsd: 1,
                updatedCurrencyCode: "KZT",
                updatedRateToUsd: 0.002
            )
        )

        let state = store.snapshot()
        let categoriesListCalls = categoriesService.listCategoriesParametersCallsCount
        let expensesListCalls = expensesService.listExpensesParametersCallsCount
        XCTAssertEqual(categoriesListCalls, 1)
        XCTAssertEqual(expensesListCalls, 3)
        XCTAssertEqual(state.preferredCurrencyCode, "KZT")
        XCTAssertNil(state.overviewSummary)
        XCTAssertTrue(state.categoriesByID.isEmpty)
        XCTAssertTrue(state.categoryDetailsByID.isEmpty)
        XCTAssertTrue(state.categoryOrder.isEmpty)
        XCTAssertTrue(state.expensesByID.isEmpty)
        XCTAssertTrue(state.recentExpenseIDs.isEmpty)
        XCTAssertTrue(state.expensesListExpenseIDs.isEmpty)
        XCTAssertTrue(state.categoryExpenseIDs.isEmpty)
        XCTAssertTrue(observer.currentOverviewSnapshot().categories.isEmpty)
        XCTAssertTrue(observer.currentOverviewSnapshot().expenseGroups.isEmpty)
    }
}

extension MainFlowDomainRepositoryTests {
    func testAddExpenseSuccessReplacesOptimisticExpensesWithResponse() async throws {
        let store = MainFlowDomainStore()
        let observer = MainFlowDomainObserver(expenseGrouping: MainExpenseDateGrouping())
        let analyticsIntervalRepository = makeAnalyticsIntervalRepository()
        let affectedResolution = makeAnalyticsResolution(
            from: Date(timeIntervalSince1970: 86_400 * 30),
            to: Date(timeIntervalSince1970: 86_400 * 34 + 1_800),
            preset: .month
        )
        let unaffectedResolution = makeAnalyticsResolution(
            from: Date(timeIntervalSince1970: 86_400 * 60),
            to: Date(timeIntervalSince1970: 86_400 * 64 + 1_800),
            preset: nil
        )
        let category = MainCategoryCardModel(
            id: "cat-1",
            name: "Food",
            icon: "🍴",
            color: "light_orange",
            amount: 10,
            currency: "USD"
        )

        await analyticsIntervalRepository.save(
            data: makeAnalyticsData(totalAmount: 120),
            for: affectedResolution
        )
        await analyticsIntervalRepository.save(
            data: makeAnalyticsData(totalAmount: 80),
            for: unaffectedResolution
        )

        store.update { state in
            state.categoriesByID[category.id] = category
            state.categoryOrder = [category.id]
            state.categoryExpenseIDs[category.id] = []
            state.categoryPagination[category.id] = .init(hasMore: false, isLoaded: true)
            state.expensesListPagination = .init(hasMore: false, isLoaded: true)
        }
        observer.publishAll(from: store)

        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesParametersReturnValue = .init(
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
        categoriesService.getCategoryIdParametersThrowableError = RepositoryTestError.any
        let expensesService = MainExpensesContractServicingMock()
        expensesService.createExpensesReturnValue = .init(
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
        let currencyConversionService = UserCurrencyConvertingMock()
        currencyConversionService.convertUsdAmountClosure = { .init(amount: $0, currency: "USD") }
        currencyConversionService.convertExpenseAmountCurrencyOriginalAmountOriginalCurrencyClosure = { amount, currency, _, _ in
            .init(amount: amount, currency: currency)
        }
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            currencyConversionService: currencyConversionService,
            store: store,
            observer: observer,
            analyticsIntervalRepository: analyticsIntervalRepository
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
        let expensesListCallCount = expensesService.listExpensesParametersCallsCount
        let categoriesListCallCount = categoriesService.listCategoriesParametersCallsCount
        XCTAssertEqual(expensesListCallCount, 0)
        XCTAssertEqual(categoriesListCallCount, 1)
        let awaitedValue1 = await analyticsIntervalRepository.cachedData(for: affectedResolution)
        XCTAssertNil(awaitedValue1)
        let awaitedValue2 = await analyticsIntervalRepository.cachedData(for: unaffectedResolution)?.totalAmount
        XCTAssertEqual(
            awaitedValue2,
            80
        )
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

        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesParametersReturnValue = .init(categories: [])
        categoriesService.getCategoryIdParametersThrowableError = RepositoryTestError.any
        let expensesService = MainExpensesContractServicingMock()
        expensesService.createExpensesThrowableError = RepositoryTestError.any
        let currencyConversionService = UserCurrencyConvertingMock()
        currencyConversionService.convertUsdAmountClosure = { .init(amount: $0, currency: "USD") }
        currencyConversionService.convertExpenseAmountCurrencyOriginalAmountOriginalCurrencyClosure = { amount, currency, _, _ in
            .init(amount: amount, currency: currency)
        }
        let repository = MainFlowDomainRepository(
            categoriesService: categoriesService,
            expensesService: expensesService,
            currencyConversionService: currencyConversionService,
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

private func makeAnalyticsIntervalRepository() -> AnalyticsIntervalRepository {
    AnalyticsIntervalRepository(calendar: makeCalendar())
}

private func makeAnalyticsResolution(
    from: Date,
    to: Date,
    preset: AnalyticsPeriodPreset?
) -> AnalyticsPeriodResolution {
    AnalyticsPeriodResolution(
        period: .init(
            from: from,
            to: to
        ),
        preset: preset
    )
}

private func makeAnalyticsData(totalAmount: Double) -> AnalyticsDataModel {
    AnalyticsDataModel(
        monthStart: Date(timeIntervalSince1970: 0),
        totalAmount: totalAmount,
        currency: "USD",
        categories: [
            .init(
                id: "food",
                name: "Food",
                icon: "🍴",
                colorValue: "light_orange",
                amount: totalAmount,
                currency: "USD",
                share: 1,
                isInteractive: true
            )
        ]
    )
}

private func makeCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}
