import Foundation

protocol MainFlowDomainRepositoryProtocol: Sendable {
    func refreshMainFlow() async throws
    func refreshCategories() async throws
    func refreshRecentExpenses() async throws
    func refreshCategoryFirstPage(id: String) async throws
    func refreshExpensesFirstPage() async throws
    func loadNextCategoryPage(id: String) async throws
    func loadNextExpensesPage() async throws
    func addExpense(_ request: ExpensesCreateRequestDTO) async throws
    func deleteExpense(id: String) async throws
    func addCategory(_ request: CategoryCreateRequestDTO) async throws
    func deleteCategory(id: String) async throws
    func clearSession() async
}

final class MainFlowDomainRepository: MainFlowDomainRepositoryProtocol, @unchecked Sendable {
    private enum Constants {
        static let overviewExpensesLimit = 5
        static let listPageLimit = 20
        static let unmappedBackendName = "Unmapped"
    }

    private let categoriesService: MainCategoriesContractServicing
    private let expensesService: MainExpensesContractServicing
    private let currencyConversionService: UserCurrencyConverting
    private let store: MainFlowDomainStoreProtocol
    private let observer: MainFlowDomainObserverProtocol

    init(
        categoriesService: MainCategoriesContractServicing,
        expensesService: MainExpensesContractServicing,
        currencyConversionService: UserCurrencyConverting,
        store: MainFlowDomainStoreProtocol,
        observer: MainFlowDomainObserverProtocol
    ) {
        self.categoriesService = categoriesService
        self.expensesService = expensesService
        self.currencyConversionService = currencyConversionService
        self.store = store
        self.observer = observer
    }

    func refreshMainFlow() async throws {
        async let categoriesTask: Void = refreshCategories()
        async let expensesTask: Void = refreshRecentExpenses()
        _ = try await (categoriesTask, expensesTask)
    }

    func refreshCategories() async throws {
        let response = try await categoriesService.listCategories()
        let categories = response.categories.map(makeCategoryModel)

        store.update { state in
            categories.forEach { state.categoriesByID[$0.id] = $0 }
            state.categoryOrder = categories.map(\.id)
        }
        observer.publishAll(from: store)
    }

    func refreshRecentExpenses() async throws {
        let response = try await expensesService.listExpenses(
            parameters: .init(limit: Constants.overviewExpensesLimit)
        )
        let expenses = response.expenses.map(makeExpenseModel)

        store.update { state in
            merge(expenses: expenses, into: &state)
            state.recentExpenseIDs = expenses.map(\.id)
            pruneUnreferencedExpenses(in: &state)
        }
        observer.publishAll(from: store)
    }

    func refreshCategoryFirstPage(id: String) async throws {
        async let categoryTask = categoriesService.getCategory(id: id)
        async let expensesTask = expensesService.listExpenses(
            parameters: .init(
                category: id,
                cursor: nil,
                limit: Constants.listPageLimit
            )
        )

        let categoryResponse = try await categoryTask
        let expensesResponse = try await expensesTask

        let category = makeCategoryModel(from: categoryResponse.category)
        let expenses = expensesResponse.expenses.map(makeExpenseModel)

        store.update { state in
            state.categoriesByID[category.id] = category
            if !state.categoryOrder.contains(category.id) {
                state.categoryOrder.append(category.id)
            }
            merge(expenses: expenses, into: &state)
            state.categoryExpenseIDs[id] = expenses.map(\.id)
            state.categoryPagination[id] = .init(
                nextCursor: expensesResponse.nextCursor,
                hasMore: expensesResponse.hasMore,
                isLoaded: true
            )
            pruneUnreferencedExpenses(in: &state)
        }
        observer.publishAll(from: store)
    }

    func refreshExpensesFirstPage() async throws {
        let response = try await expensesService.listExpenses(
            parameters: .init(limit: Constants.listPageLimit)
        )
        let expenses = response.expenses.map(makeExpenseModel)

        store.update { state in
            merge(expenses: expenses, into: &state)
            state.expensesListExpenseIDs = expenses.map(\.id)
            state.expensesListPagination = .init(
                nextCursor: response.nextCursor,
                hasMore: response.hasMore,
                isLoaded: true
            )
            pruneUnreferencedExpenses(in: &state)
        }
        observer.publishAll(from: store)
    }

    func loadNextCategoryPage(id: String) async throws {
        let state = store.snapshot()
        let pagination = state.categoryPagination[id] ?? .init()

        guard pagination.isLoaded, pagination.hasMore else {
            return
        }

        let response = try await expensesService.listExpenses(
            parameters: .init(
                category: id,
                cursor: pagination.nextCursor,
                limit: Constants.listPageLimit
            )
        )
        let expenses = response.expenses.map(makeExpenseModel)

        store.update { state in
            merge(expenses: expenses, into: &state)
            let currentIDs = state.categoryExpenseIDs[id] ?? []
            state.categoryExpenseIDs[id] = uniqueExpenseIDs(
                currentIDs + expenses.map(\.id),
                from: state
            )
            state.categoryPagination[id] = .init(
                nextCursor: response.nextCursor,
                hasMore: response.hasMore,
                isLoaded: true
            )
            pruneUnreferencedExpenses(in: &state)
        }
        observer.publishAll(from: store)
    }

    func loadNextExpensesPage() async throws {
        let state = store.snapshot()
        let pagination = state.expensesListPagination

        guard pagination.isLoaded, pagination.hasMore else {
            return
        }

        let response = try await expensesService.listExpenses(
            parameters: .init(
                cursor: pagination.nextCursor,
                limit: Constants.listPageLimit
            )
        )
        let expenses = response.expenses.map(makeExpenseModel)

        store.update { state in
            merge(expenses: expenses, into: &state)
            state.expensesListExpenseIDs = uniqueExpenseIDs(
                state.expensesListExpenseIDs + expenses.map(\.id),
                from: state
            )
            state.expensesListPagination = .init(
                nextCursor: response.nextCursor,
                hasMore: response.hasMore,
                isLoaded: true
            )
            pruneUnreferencedExpenses(in: &state)
        }
        observer.publishAll(from: store)
    }

    func addExpense(_ request: ExpensesCreateRequestDTO) async throws {
        let previousState = store.snapshot()
        let optimisticExpenses = request.expenses.map(makeOptimisticExpenseModel)
        let affectedCategoryIDs = Set(request.expenses.map(\.category))

        store.update { state in
            merge(expenses: optimisticExpenses, into: &state)
            insertExpensesIntoRecent(optimisticExpenses, state: &state)
            insertExpensesIntoExpensesList(optimisticExpenses, state: &state)
            insertExpensesIntoCategories(optimisticExpenses, state: &state)
            applyCategoryAmountDelta(for: optimisticExpenses, multiplier: 1, state: &state)
            pruneUnreferencedExpenses(in: &state)
        }
        observer.publishAll(from: store)

        do {
            _ = try await expensesService.createExpenses(request)
            try await reconcileAfterExpenseMutation(affectedCategoryIDs: affectedCategoryIDs)
        } catch {
            store.replaceState(previousState)
            observer.publishAll(from: store)
            throw error
        }
    }

    func deleteExpense(id: String) async throws {
        let previousState = store.snapshot()

        guard let deletedExpense = previousState.expensesByID[id] else {
            return
        }

        store.update { state in
            state.pendingDeletedExpenseIDs.insert(id)
            removeExpense(id: id, from: &state)
            applyCategoryAmountDelta(for: [deletedExpense], multiplier: -1, state: &state)
            pruneUnreferencedExpenses(in: &state)
        }
        observer.publishAll(from: store)

        do {
            try await expensesService.deleteExpense(id: id)
            store.update { state in
                state.pendingDeletedExpenseIDs.remove(id)
            }
            observer.publishAll(from: store)
            try await reconcileAfterExpenseMutation(
                affectedCategoryIDs: Set([deletedExpense.category])
            )
        } catch {
            store.replaceState(previousState)
            observer.publishAll(from: store)
            throw error
        }
    }

    func addCategory(_ request: CategoryCreateRequestDTO) async throws {
        let previousState = store.snapshot()
        let optimisticCategoryID = "optimistic-category-\(UUID().uuidString)"
        let optimisticCategory = MainCategoryCardModel(
            id: optimisticCategoryID,
            name: localizedCategoryName(from: request.name),
            icon: request.icon,
            color: request.color,
            amount: .zero,
            currency: currentCurrencyCode(from: previousState)
        )

        store.update { state in
            state.categoriesByID[optimisticCategory.id] = optimisticCategory
            state.categoryOrder.insert(optimisticCategory.id, at: .zero)
        }
        observer.publishAll(from: store)

        do {
            _ = try await categoriesService.createCategory(request)
            try await refreshCategories()
        } catch {
            store.replaceState(previousState)
            observer.publishAll(from: store)
            throw error
        }
    }

    func deleteCategory(id: String) async throws {
        let previousState = store.snapshot()

        store.update { state in
            state.categoriesByID[id] = nil
            state.categoryOrder.removeAll { $0 == id }
            state.categoryExpenseIDs[id] = nil
            state.categoryPagination[id] = nil
            pruneUnreferencedExpenses(in: &state)
        }
        observer.publishAll(from: store)

        do {
            try await categoriesService.deleteCategory(id: id)
            try await refreshCategories()
        } catch {
            store.replaceState(previousState)
            observer.publishAll(from: store)
            throw error
        }
    }

    func clearSession() async {
        store.clear()
        observer.finishAll()
    }
}

private extension MainFlowDomainRepository {
    func reconcileAfterExpenseMutation(affectedCategoryIDs: Set<String>) async throws {
        try await refreshCategories()
        try await refreshRecentExpenses()

        let state = store.snapshot()
        if state.expensesListPagination.isLoaded {
            try await refreshExpensesFirstPage()
        }

        for categoryID in affectedCategoryIDs where state.categoryPagination[categoryID]?.isLoaded == true {
            try await refreshCategoryFirstPage(id: categoryID)
        }
    }

    func merge(expenses: [MainExpenseModel], into state: inout MainFlowDomainState) {
        expenses.forEach {
            state.expensesByID[$0.id] = $0
        }
    }

    func insertExpensesIntoRecent(
        _ expenses: [MainExpenseModel],
        state: inout MainFlowDomainState
    ) {
        let combinedIDs = expenses.map(\.id) + state.recentExpenseIDs
        state.recentExpenseIDs = uniqueExpenseIDs(combinedIDs, from: state)
            .prefix(Constants.overviewExpensesLimit)
            .map { $0 }
    }

    func insertExpensesIntoExpensesList(
        _ expenses: [MainExpenseModel],
        state: inout MainFlowDomainState
    ) {
        guard state.expensesListPagination.isLoaded else {
            return
        }

        state.expensesListExpenseIDs = uniqueExpenseIDs(
            expenses.map(\.id) + state.expensesListExpenseIDs,
            from: state
        )
    }

    func insertExpensesIntoCategories(
        _ expenses: [MainExpenseModel],
        state: inout MainFlowDomainState
    ) {
        let categoryIDs = Set(expenses.map(\.category))

        for categoryID in categoryIDs where state.categoryPagination[categoryID]?.isLoaded == true {
            let insertedIDs = expenses
                .filter { $0.category == categoryID }
                .map(\.id)

            state.categoryExpenseIDs[categoryID] = uniqueExpenseIDs(
                insertedIDs + (state.categoryExpenseIDs[categoryID] ?? []),
                from: state
            )
        }
    }

    func removeExpense(id: String, from state: inout MainFlowDomainState) {
        state.recentExpenseIDs.removeAll { $0 == id }
        state.expensesListExpenseIDs.removeAll { $0 == id }
        state.categoryExpenseIDs.keys.forEach { categoryID in
            state.categoryExpenseIDs[categoryID]?.removeAll { $0 == id }
        }
    }

    func pruneUnreferencedExpenses(in state: inout MainFlowDomainState) {
        let referencedIDs = Set(state.recentExpenseIDs)
            .union(state.expensesListExpenseIDs)
            .union(state.pendingDeletedExpenseIDs)
            .union(
                state.categoryExpenseIDs.values.flatMap { $0 }
            )

        state.expensesByID = state.expensesByID.filter { referencedIDs.contains($0.key) }
    }

    func applyCategoryAmountDelta(
        for expenses: [MainExpenseModel],
        multiplier: Double,
        state: inout MainFlowDomainState
    ) {
        let groupedExpenses = Dictionary(grouping: expenses, by: \.category)

        groupedExpenses.forEach { categoryID, expenses in
            guard var category = state.categoriesByID[categoryID] else {
                return
            }

            let delta = expenses.reduce(.zero) { partialResult, expense in
                partialResult + expense.amount
            } * multiplier

            category = MainCategoryCardModel(
                id: category.id,
                name: category.name,
                icon: category.icon,
                color: category.color,
                amount: max(.zero, category.amount + delta),
                currency: category.currency
            )
            state.categoriesByID[categoryID] = category
        }
    }

    func uniqueExpenseIDs(
        _ ids: [String],
        from state: MainFlowDomainState
    ) -> [String] {
        var seenIDs: Set<String> = []
        let uniqueIDs = ids.filter { seenIDs.insert($0).inserted }

        return uniqueIDs.sorted { lhs, rhs in
            guard let leftExpense = state.expensesByID[lhs],
                  let rightExpense = state.expensesByID[rhs]
            else {
                return lhs < rhs
            }

            return leftExpense.timeOfAdd > rightExpense.timeOfAdd
        }
    }

    func makeCategoryModel(from category: CategoryDTO) -> MainCategoryCardModel {
        let convertedAmount = currencyConversionService.convertUsdAmount(category.totalSpentUsd ?? .zero)
        return MainCategoryCardModel(
            id: category.id,
            name: localizedCategoryName(from: category.name),
            icon: category.icon,
            color: category.color,
            amount: convertedAmount.amount,
            currency: convertedAmount.currency
        )
    }

    func makeExpenseModel(from expense: ExpenseDTO) -> MainExpenseModel {
        let convertedAmount = currencyConversionService.convertExpense(
            amount: expense.amount,
            currency: expense.currency
        )

        return MainExpenseModel(
            id: expense.id,
            title: expense.title,
            description: expense.description ?? "",
            amount: convertedAmount.amount,
            currency: convertedAmount.currency,
            category: expense.category,
            timeOfAdd: expense.timeOfAdd
        )
    }

    func makeOptimisticExpenseModel(from expense: ExpenseCreateItemRequestDTO) -> MainExpenseModel {
        let convertedAmount = currencyConversionService.convertExpense(
            amount: expense.amount,
            currency: expense.currency
        )

        return MainExpenseModel(
            id: "optimistic-expense-\(UUID().uuidString)",
            title: expense.title,
            description: expense.description,
            amount: convertedAmount.amount,
            currency: convertedAmount.currency,
            category: expense.category,
            timeOfAdd: expense.timeOfAdd
        )
    }

    func localizedCategoryName(from backendName: String) -> String {
        if backendName.compare(Constants.unmappedBackendName, options: [.caseInsensitive]) == .orderedSame {
            return L10n.other
        }

        return backendName
    }

    func currentCurrencyCode(from state: MainFlowDomainState) -> String {
        state.categoriesByID.values.first?.currency ?? Locale.current.currency?.identifier ?? "USD"
    }
}
