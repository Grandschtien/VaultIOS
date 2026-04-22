import Foundation

protocol MainFlowDomainRepositoryProtocol: Sendable {
    func refreshMainFlow() async throws
    func refreshCategories() async throws
    func refreshRecentExpenses() async throws
    func refreshCategoryFirstPage(id: String, fromDate: Date?, toDate: Date?) async throws
    func refreshExpensesFirstPage() async throws
    func refreshLoadedPeriodDependentModules() async
    func handleCurrencyDidChange(_ payload: ProfileCurrencyDidChangePayload) async
    func loadNextCategoryPage(id: String) async throws
    func loadNextExpensesPage() async throws
    func addExpense(_ request: ExpensesCreateRequestDTO) async throws
    func deleteExpense(id: String) async throws
    func addCategory(_ request: CategoryCreateRequestDTO) async throws -> MainCategoryCardModel
    func updateCategory(id: String, request: CategoryCreateRequestDTO) async throws -> MainCategoryCardModel
    func deleteCategory(id: String) async throws
    func clearSession() async
}

extension MainFlowDomainRepositoryProtocol {
    func refreshCategoryFirstPage(id: String) async throws {
        try await refreshCategoryFirstPage(
            id: id,
            fromDate: nil,
            toDate: nil
        )
    }

    func refreshCategoryFirstPage(id: String, fromDate: Date?) async throws {
        try await refreshCategoryFirstPage(
            id: id,
            fromDate: fromDate,
            toDate: nil
        )
    }

    func addCategory(_ request: CategoryCreateRequestDTO) async throws -> MainCategoryCardModel {
        MainCategoryCardModel(
            id: "",
            name: request.name,
            icon: request.icon,
            color: request.color,
            amount: .zero,
            currency: "USD"
        )
    }

    func updateCategory(
        id: String,
        request: CategoryCreateRequestDTO
    ) async throws -> MainCategoryCardModel {
        MainCategoryCardModel(
            id: id,
            name: request.name,
            icon: request.icon,
            color: request.color,
            amount: .zero,
            currency: "USD"
        )
    }

    func refreshLoadedPeriodDependentModules() async {}
}

final class MainFlowDomainRepository: MainFlowDomainRepositoryProtocol, @unchecked Sendable {
    private enum Constants {
        static let overviewExpensesLimit = 5
        static let listPageLimit = 20
        static let unmappedBackendName = "Unmapped"
        static let usdCurrencyCode = "USD"
    }

    private let categoriesService: MainCategoriesContractServicing
    private let expensesService: MainExpensesContractServicing
    private let summaryService: MainSummaryContractServicing?
    private let summaryPeriodProvider: MainSummaryPeriodProviding?
    private let currencyConversionService: UserCurrencyConverting
    private let store: MainFlowDomainStoreProtocol
    private let observer: MainFlowDomainObserverProtocol
    private let now: @Sendable () -> Date
    private let periodResolver: MainPeriodRangeResolver

    init(
        categoriesService: MainCategoriesContractServicing,
        expensesService: MainExpensesContractServicing,
        summaryService: MainSummaryContractServicing? = nil,
        summaryPeriodProvider: MainSummaryPeriodProviding? = nil,
        currencyConversionService: UserCurrencyConverting,
        store: MainFlowDomainStoreProtocol,
        observer: MainFlowDomainObserverProtocol,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.categoriesService = categoriesService
        self.expensesService = expensesService
        self.summaryService = summaryService
        self.summaryPeriodProvider = summaryPeriodProvider
        self.currencyConversionService = currencyConversionService
        self.store = store
        self.observer = observer
        self.now = now
        periodResolver = MainPeriodRangeResolver(calendar: calendar)
    }

    func refreshMainFlow() async throws {
        async let categoriesTask: Void = refreshCategories()
        async let expensesTask: Void = refreshRecentExpenses()
        _ = try await (categoriesTask, expensesTask)
    }

    func refreshCategories() async throws {
        let response = try await categoriesService.listCategories(
            parameters: makeCategoriesQueryParameters(
                period: summaryPeriodProvider?.currentMonthPeriod()
            )
        )
        let categories = response.categories.map { makeCategoryModel(from: $0) }

        store.update { state in
            categories.forEach { state.categoriesByID[$0.id] = $0 }
            state.categoryOrder = categories.map(\.id)
            state.preferredCurrencyCode = categories.first?.currency ?? state.preferredCurrencyCode
        }
        observer.publishAll(from: store)
    }

    func refreshRecentExpenses() async throws {
        let parameters: ExpensesListQueryParameters
        if let summaryPeriodProvider {
            let period = summaryPeriodProvider.currentMonthPeriod()
            parameters = .init(
                from: period.from,
                to: period.to,
                limit: Constants.overviewExpensesLimit
            )
        } else {
            parameters = .init(limit: Constants.overviewExpensesLimit)
        }

        let response = try await expensesService.listExpenses(parameters: parameters)
        let expenses = response.expenses.map(makeExpenseModel)

        store.update { state in
            merge(expenses: expenses, into: &state)
            state.recentExpenseIDs = expenses.map(\.id)
            pruneUnreferencedExpenses(in: &state)
        }
        observer.publishAll(from: store)
    }

    func refreshCategoryFirstPage(
        id: String,
        fromDate: Date?,
        toDate: Date?
    ) async throws {
        let resolvedPeriod = resolvedCategoryPeriod(
            for: id,
            overridingFromDate: fromDate,
            overridingToDate: toDate
        )
        resetCategoryScopeIfNeeded(
            id: id,
            period: resolvedPeriod
        )
        async let categoryTask = categoriesService.getCategory(
            id: id,
            parameters: makeCategoriesQueryParameters(period: resolvedPeriod)
        )
        async let expensesTask = expensesService.listExpenses(
            parameters: makeCategoryExpensesQueryParameters(
                categoryID: id,
                period: resolvedPeriod,
                cursor: nil,
                limit: Constants.listPageLimit
            )
        )
        async let categorySummaryTask = fetchCategorySummary(
            for: id,
            period: resolvedPeriod
        )

        let categoryResponse = try await categoryTask
        let expensesResponse = try await expensesTask
        let categorySummary = await categorySummaryTask

        let category = makeCategoryDetailModel(
            from: categoryResponse.category,
            summary: categorySummary
        )
        let expenses = expensesResponse.expenses.map(makeExpenseModel)

        store.update { state in
            if let existingCategory = state.categoriesByID[category.id] {
                state.categoriesByID[category.id] = MainCategoryCardModel(
                    id: existingCategory.id,
                    name: localizedCategoryName(from: categoryResponse.category.name),
                    icon: categoryResponse.category.icon,
                    color: categoryResponse.category.color,
                    amount: existingCategory.amount,
                    currency: existingCategory.currency
                )
            }

            state.categoryDetailsByID[category.id] = category
            state.categoryPeriods[id] = resolvedPeriod
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
            parameters: makeExpensesListQueryParameters(
                cursor: nil,
                limit: Constants.listPageLimit
            )
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

    func refreshLoadedPeriodDependentModules() async {
        guard let summaryPeriodProvider else {
            return
        }

        let state = store.snapshot()
        let period = summaryPeriodProvider.currentMonthPeriod()
        let loadedCategoryIDs = state.categoryPagination.compactMap { element -> String? in
            element.value.isLoaded ? element.key : nil
        }

        if state.expensesListPagination.isLoaded {
            try? await refreshExpensesFirstPage()
        }

        for categoryID in loadedCategoryIDs {
            try? await refreshCategoryFirstPage(
                id: categoryID,
                fromDate: period.from,
                toDate: period.to
            )
        }
    }

    func handleCurrencyDidChange(_ payload: ProfileCurrencyDidChangePayload) async {
        let state = store.snapshot()
        let updatedCurrencyCode = normalizedCurrencyCode(payload.updatedCurrencyCode)
        let shouldRefreshExpensesList = state.expensesListPagination.isLoaded
        let loadedCategoryTargets = state.categoryPagination.compactMap {
            element -> LoadedCategoryTarget? in
            guard element.value.isLoaded else {
                return nil
            }

            return LoadedCategoryTarget(
                id: element.key,
                period: state.categoryPeriods[element.key]
            )
        }

        invalidateCurrencyDependentState(updatedCurrencyCode: updatedCurrencyCode)
        observer.publishAll(from: store)

        async let summaryTask: Void = {
            try? await refreshOverviewSummary()
        }()
        async let categoriesTask: Void = {
            try? await refreshCategories()
        }()
        async let recentExpensesTask: Void = {
            try? await refreshRecentExpenses()
        }()

        _ = await (summaryTask, categoriesTask, recentExpensesTask)

        if shouldRefreshExpensesList {
            try? await refreshExpensesFirstPage()
        }

        for categoryTarget in loadedCategoryTargets {
            try? await refreshCategoryFirstPage(
                id: categoryTarget.id,
                fromDate: categoryTarget.period?.from,
                toDate: categoryTarget.period?.to
            )
        }
    }

    func loadNextCategoryPage(id: String) async throws {
        let state = store.snapshot()
        let pagination = state.categoryPagination[id] ?? .init()

        guard pagination.isLoaded, pagination.hasMore else {
            return
        }

        let response = try await expensesService.listExpenses(
            parameters: makeCategoryExpensesQueryParameters(
                categoryID: id,
                period: resolvedCategoryPeriod(for: id),
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
            parameters: makeExpensesListQueryParameters(
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
            let response = try await expensesService.createExpenses(request)
            let responseExpenses = response.expenses.map(makeExpenseModel)
            let optimisticExpenseIDs = optimisticExpenses.map(\.id)

            store.update { state in
                removeExpenses(ids: optimisticExpenseIDs, from: &state)
                applyCategoryAmountDelta(for: optimisticExpenses, multiplier: -1, state: &state)
                merge(expenses: responseExpenses, into: &state)
                insertExpensesIntoRecent(responseExpenses, state: &state)
                insertExpensesIntoExpensesList(responseExpenses, state: &state)
                insertExpensesIntoCategories(responseExpenses, state: &state)
                applyCategoryAmountDelta(for: responseExpenses, multiplier: 1, state: &state)
                pruneUnreferencedExpenses(in: &state)
            }
            observer.publishAll(from: store)

            try? await refreshCategories()
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

    func addCategory(_ request: CategoryCreateRequestDTO) async throws -> MainCategoryCardModel {
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
            let response = try await categoriesService.createCategory(request)
            let createdCategory = makeCategoryModel(from: response.category)

            store.update { state in
                state.categoriesByID[optimisticCategoryID] = nil
                state.categoryOrder.removeAll { $0 == optimisticCategoryID }
                state.categoriesByID[createdCategory.id] = createdCategory
                state.categoryOrder.insert(createdCategory.id, at: .zero)
            }
            observer.publishAll(from: store)

            try? await refreshCategories()

            return observer.currentCategoriesSnapshot().categories.first {
                $0.id == createdCategory.id
            } ?? createdCategory
        } catch {
            store.replaceState(previousState)
            observer.publishAll(from: store)
            throw error
        }
    }

    func updateCategory(
        id: String,
        request: CategoryCreateRequestDTO
    ) async throws -> MainCategoryCardModel {
        let previousState = store.snapshot()

        store.update { state in
            updateCategory(
                id: id,
                name: localizedCategoryName(from: request.name),
                icon: request.icon,
                color: request.color,
                state: &state
            )
        }
        observer.publishAll(from: store)

        do {
            let response = try await categoriesService.updateCategory(id: id, request: request)
            let fallbackCategory = previousState.categoryDetailsByID[id] ?? previousState.categoriesByID[id]
            let updatedCategory = makeEditableCategoryModel(
                from: response.category,
                fallbackCategory: fallbackCategory
            )

            store.update { state in
                updateCategory(
                    id: id,
                    name: updatedCategory.name,
                    icon: updatedCategory.icon,
                    color: updatedCategory.color,
                    state: &state
                )
            }
            observer.publishAll(from: store)

            try? await refreshCategories()

            if previousState.categoryPagination[id]?.isLoaded == true {
                try? await refreshCategoryFirstPage(
                    id: id,
                    fromDate: previousState.categoryPeriods[id]?.from,
                    toDate: previousState.categoryPeriods[id]?.to
                )
            }

            return observer.currentCategorySnapshot(id: id).category
                ?? observer.currentCategoriesSnapshot().categories.first(where: { $0.id == id })
                ?? updatedCategory
        } catch {
            store.replaceState(previousState)
            observer.publishAll(from: store)
            throw error
        }
    }

    func deleteCategory(id: String) async throws {
        let previousState = store.snapshot()

        store.update { state in
            state.overviewSummary = nil
            state.categoriesByID[id] = nil
            state.categoryDetailsByID[id] = nil
            state.categoryOrder.removeAll { $0 == id }
            state.categoryExpenseIDs[id] = nil
            state.categoryPagination[id] = nil
            state.categoryPeriods[id] = nil
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
    struct LoadedCategoryTarget {
        let id: String
        let period: MainSummaryPeriod?
    }

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
                .filter { shouldIncludeInCategoryDetails($0, categoryID: categoryID, state: state) }
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

    func removeExpenses(
        ids: [String],
        from state: inout MainFlowDomainState
    ) {
        ids.forEach { id in
            removeExpense(id: id, from: &state)
            state.expensesByID[id] = nil
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
        guard !expenses.isEmpty else {
            return
        }

        state.overviewSummary = nil
        let groupedExpenses = Dictionary(grouping: expenses, by: \.category)

        groupedExpenses.forEach { categoryID, expenses in
            guard var category = state.categoriesByID[categoryID] else {
                applyCategoryDetailAmountDelta(
                    for: expenses,
                    categoryID: categoryID,
                    multiplier: multiplier,
                    state: &state
                )
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

            applyCategoryDetailAmountDelta(
                for: expenses,
                categoryID: categoryID,
                multiplier: multiplier,
                state: &state
            )
        }
    }

    func applyCategoryDetailAmountDelta(
        for expenses: [MainExpenseModel],
        categoryID: String,
        multiplier: Double,
        state: inout MainFlowDomainState
    ) {
        guard var category = state.categoryDetailsByID[categoryID] else {
            return
        }

        let filteredExpenses = expenses.filter {
            shouldIncludeInCategoryDetails($0, categoryID: categoryID, state: state)
        }
        let delta = filteredExpenses.reduce(.zero) { partialResult, expense in
            partialResult + expense.amount
        } * multiplier

        guard delta != .zero else {
            return
        }

        category = MainCategoryCardModel(
            id: category.id,
            name: category.name,
            icon: category.icon,
            color: category.color,
            amount: max(.zero, category.amount + delta),
            currency: category.currency
        )
        state.categoryDetailsByID[categoryID] = category
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

    func invalidateCurrencyDependentState(updatedCurrencyCode: String) {
        store.update { state in
            state.preferredCurrencyCode = updatedCurrencyCode.isEmpty ? nil : updatedCurrencyCode
            state.overviewSummary = nil
            state.categoriesByID = [:]
            state.categoryDetailsByID = [:]
            state.categoryOrder = []
            state.expensesByID = [:]
            state.recentExpenseIDs = []
            state.expensesListExpenseIDs = []
            state.expensesListPagination = .init(
                hasMore: false,
                isLoaded: state.expensesListPagination.isLoaded
            )
            state.categoryExpenseIDs = [:]
            state.categoryPagination = state.categoryPagination.mapValues { pagination in
                .init(hasMore: false, isLoaded: pagination.isLoaded)
            }
            state.pendingDeletedExpenseIDs = Set<String>()
        }
    }

    func normalizedCurrencyCode(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    func isSameCurrency(_ lhs: String, _ rhs: String) -> Bool {
        lhs.compare(rhs, options: [.caseInsensitive]) == .orderedSame
    }

    func makeCategoryModel(
        from category: CategoryDTO
    ) -> MainCategoryCardModel {
        return MainCategoryCardModel(
            id: category.id,
            name: localizedCategoryName(from: category.name),
            icon: category.icon,
            color: category.color,
            amount: category.displayedAmount,
            currency: category.displayedCurrency
        )
    }

    func makeCategoryDetailModel(
        from category: CategoryDTO,
        summary: CategorySummaryAmount?
    ) -> MainCategoryCardModel {
        return MainCategoryCardModel(
            id: category.id,
            name: localizedCategoryName(from: category.name),
            icon: category.icon,
            color: category.color,
            amount: summary?.amount ?? category.displayedAmount,
            currency: summary?.currency ?? category.displayedCurrency
        )
    }

    func makeExpenseModel(from expense: ExpenseDTO) -> MainExpenseModel {
        let convertedAmount = currencyConversionService.convertExpense(
            amount: expense.amount,
            currency: expense.currency,
            originalAmount: expense.originalAmount,
            originalCurrency: expense.originalCurrency
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
            currency: expense.currency,
            originalAmount: nil,
            originalCurrency: nil
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
        state.categoriesByID.values.first?.currency
            ?? state.preferredCurrencyCode
            ?? Locale.current.currency?.identifier
            ?? "USD"
    }

    func fetchMonthlyCategoryTotals() async -> [String: Double]? {
        guard let summaryService, let summaryPeriodProvider else {
            return nil
        }

        let period = summaryPeriodProvider.currentMonthPeriod()

        do {
            let response = try await summaryService.getSummary(
                parameters: .init(
                    from: period.from,
                    to: period.to
                )
            )

            return response.byCategory?.reduce(into: [String: Double]()) { partialResult, categorySummary in
                partialResult[categorySummary.category] = categorySummary.total
            }
        } catch {
            return nil
        }
    }

    func refreshOverviewSummary() async throws {
        guard let summaryService, let summaryPeriodProvider else {
            return
        }

        let period = summaryPeriodProvider.currentMonthPeriod()
        let response = try await summaryService.getSummary(
            parameters: .init(
                from: period.from,
                to: period.to
            )
        )
        let summary = makeOverviewSummaryModel(from: response)
        let preferredCurrencyCode = normalizedCurrencyCode(summary.currency)

        store.update { state in
            state.overviewSummary = summary
            state.preferredCurrencyCode = preferredCurrencyCode.isEmpty ? nil : preferredCurrencyCode
        }
        observer.publishAll(from: store)
    }

    func fetchCategorySummary(
        for categoryID: String,
        period: MainSummaryPeriod?
    ) async -> CategorySummaryAmount? {
        guard let summaryService else {
            return nil
        }

        do {
            let response = try await summaryService.getSummaryByCategory(
                id: categoryID,
                parameters: .init(
                    from: period?.from,
                    to: period?.to
                )
            )

            return makeCategorySummaryAmount(from: response)
        } catch {
            return nil
        }
    }

    func makeCategorySummaryAmount(from response: SummaryResponseDTO) -> CategorySummaryAmount {
        let currency = normalizedCurrencyCode(response.currency)
        return .init(
            amount: response.total,
            currency: currency.isEmpty ? Constants.usdCurrencyCode : currency
        )
    }

    func makeOverviewSummaryModel(from response: SummaryResponseDTO) -> MainSummaryModel {
        let currency = normalizedCurrencyCode(response.currency)

        return MainSummaryModel(
            totalAmount: response.total,
            currency: currency.isEmpty ? Constants.usdCurrencyCode : currency,
            changePercent: .zero
        )
    }

    func makeCategoryExpensesQueryParameters(
        categoryID: String,
        period: MainSummaryPeriod?,
        cursor: String?,
        limit: Int
    ) -> ExpensesListQueryParameters {
        return .init(
            category: categoryID,
            from: period?.from,
            to: period?.to,
            cursor: cursor,
            limit: limit
        )
    }

    func makeExpensesListQueryParameters(
        cursor: String?,
        limit: Int
    ) -> ExpensesListQueryParameters {
        let period = summaryPeriodProvider?.currentMonthPeriod()

        return .init(
            from: period?.from,
            to: period?.to,
            cursor: cursor,
            limit: limit
        )
    }

    func makeCategoriesQueryParameters(
        period: MainSummaryPeriod?
    ) -> CategoriesQueryParameters {
        .init(
            from: period?.from,
            to: period?.to
        )
    }

    func resolvedCategoryPeriod(
        for categoryID: String,
        overridingFromDate: Date? = nil,
        overridingToDate: Date? = nil
    ) -> MainSummaryPeriod? {
        if let overridingFromDate {
            return explicitCategoryPeriod(
                fromDate: overridingFromDate,
                toDate: overridingToDate
            )
        }

        let state = store.snapshot()
        if let storedPeriod = state.categoryPeriods[categoryID] {
            return normalizedStoredCategoryPeriod(storedPeriod)
        }

        return summaryPeriodProvider.map { period in
            normalizedStoredCategoryPeriod(period.currentMonthPeriod())
        }
    }

    func explicitCategoryPeriod(
        fromDate: Date,
        toDate: Date?
    ) -> MainSummaryPeriod {
        periodResolver.resolvedPeriod(
            from: fromDate,
            to: toDate,
            now: now()
        )
    }

    func normalizedStoredCategoryPeriod(_ period: MainSummaryPeriod) -> MainSummaryPeriod {
        MainSummaryPeriod(
            from: periodResolver.startOfDay(for: period.from),
            to: period.to
        )
    }

    func resetCategoryScopeIfNeeded(
        id: String,
        period: MainSummaryPeriod?
    ) {
        let currentState = store.snapshot()
        guard currentState.categoryPeriods[id] != period else {
            return
        }

        store.update { state in
            state.categoryPeriods[id] = period
            state.categoryExpenseIDs[id] = []
            state.categoryPagination[id] = .init()
            pruneUnreferencedExpenses(in: &state)
        }
    }

    func shouldIncludeInCategoryDetails(
        _ expense: MainExpenseModel,
        categoryID: String,
        state: MainFlowDomainState
    ) -> Bool {
        guard expense.category == categoryID else {
            return false
        }

        guard let period = state.categoryPeriods[categoryID].map(normalizedStoredCategoryPeriod) else {
            return true
        }

        return expense.timeOfAdd >= period.from
            && expense.timeOfAdd <= period.to
    }

    func updateCategory(
        id: String,
        name: String,
        icon: String,
        color: String,
        state: inout MainFlowDomainState
    ) {
        if let category = state.categoriesByID[id] {
            state.categoriesByID[id] = MainCategoryCardModel(
                id: category.id,
                name: name,
                icon: icon,
                color: color,
                amount: category.amount,
                currency: category.currency
            )
        }

        if let category = state.categoryDetailsByID[id] {
            state.categoryDetailsByID[id] = MainCategoryCardModel(
                id: category.id,
                name: name,
                icon: icon,
                color: color,
                amount: category.amount,
                currency: category.currency
            )
        }
    }

    func makeEditableCategoryModel(
        from category: CategoryDTO,
        fallbackCategory: MainCategoryCardModel?
    ) -> MainCategoryCardModel {
        guard let fallbackCategory else {
            return makeCategoryModel(from: category)
        }

        return MainCategoryCardModel(
            id: category.id,
            name: localizedCategoryName(from: category.name),
            icon: category.icon,
            color: category.color,
            amount: fallbackCategory.amount,
            currency: fallbackCategory.currency
        )
    }
}

private struct CategorySummaryAmount: Equatable, Sendable {
    let amount: Double
    let currency: String
}
