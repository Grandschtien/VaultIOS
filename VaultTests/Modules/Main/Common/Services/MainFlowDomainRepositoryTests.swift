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
    private var listCalls = 0

    init(listResult: Result<CategoriesResponseDTO, Error>) {
        self.listResult = listResult
    }

    func createCategory(_ request: CategoryCreateRequestDTO) async throws -> CategoryResponseDTO {
        throw RepositoryTestError.any
    }

    func listCategories() async throws -> CategoriesResponseDTO {
        listCalls += 1
        try listResult.get()
    }

    func getCategory(id: String) async throws -> CategoryResponseDTO {
        throw RepositoryTestError.any
    }

    func deleteCategory(id: String) async throws {}

    func listCallsCount() -> Int {
        listCalls
    }
}

private actor ExpensesServiceStub: MainExpensesContractServicing {
    private let listResults: [Result<ExpensesListResponseDTO, Error>]
    private let createResult: Result<ExpensesCreateResponseDTO, Error>
    private let deleteResult: Result<Void, Error>
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
}
