import Foundation

protocol MainFlowDomainRepositoryProtocol: Sendable {
    func refreshMainFlow() async throws
    func refreshCategories() async throws
    func refreshRecentExpenses() async throws
    func refreshCategoryFirstPage(id: String, fromDate: Date?) async throws
    func refreshExpensesFirstPage() async throws
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
        try await refreshCategoryFirstPage(id: id, fromDate: nil)
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
}

final class MainFlowDomainRepository: MainFlowDomainRepositoryProtocol, @unchecked Sendable {
    private enum Constants {
        static let overviewExpensesLimit = 5
        static let listPageLimit = 20
        static let unmappedBackendName = "Unmapped"
    }

    private let categoriesService: MainCategoriesContractServicing
    private let expensesService: MainExpensesContractServicing
    private let summaryService: MainSummaryContractServicing?
    private let summaryPeriodProvider: MainSummaryPeriodProviding?
    private let currencyConversionService: UserCurrencyConverting
    private let store: MainFlowDomainStoreProtocol
    private let observer: MainFlowDomainObserverProtocol

    init(
        categoriesService: MainCategoriesContractServicing,
        expensesService: MainExpensesContractServicing,
        summaryService: MainSummaryContractServicing? = nil,
        summaryPeriodProvider: MainSummaryPeriodProviding? = nil,
        currencyConversionService: UserCurrencyConverting,
        store: MainFlowDomainStoreProtocol,
        observer: MainFlowDomainObserverProtocol
    ) {
        self.categoriesService = categoriesService
        self.expensesService = expensesService
        self.summaryService = summaryService
        self.summaryPeriodProvider = summaryPeriodProvider
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
        async let categoriesTask = categoriesService.listCategories()
        async let monthlyTotalsTask = fetchMonthlyCategoryTotals()

        let response = try await categoriesTask
        let monthlyTotals = await monthlyTotalsTask
        let categories = response.categories.map { makeCategoryModel(from: $0, monthlyTotals: monthlyTotals) }

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

    func refreshCategoryFirstPage(id: String, fromDate: Date?) async throws {
        let resolvedFromDate = resolvedCategoryFromDate(
            for: id,
            overridingFromDate: fromDate
        )
        async let categoryTask = categoriesService.getCategory(id: id)
        async let expensesTask = expensesService.listExpenses(
            parameters: makeCategoryExpensesQueryParameters(
                categoryID: id,
                fromDate: resolvedFromDate,
                cursor: nil,
                limit: Constants.listPageLimit
            )
        )
        async let categoryTotalTask = fetchCategoryTotal(
            for: id,
            fromDate: resolvedFromDate
        )

        let categoryResponse = try await categoryTask
        let expensesResponse = try await expensesTask
        let categoryTotal = await categoryTotalTask

        let category = makeCategoryDetailModel(
            from: categoryResponse.category,
            total: categoryTotal
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
            if let resolvedFromDate {
                state.categoryFromDates[id] = resolvedFromDate
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

    func handleCurrencyDidChange(_ payload: ProfileCurrencyDidChangePayload) async {
        let didRecalculateCategories = recalculateOverviewCategoriesIfPossible(with: payload)
        if didRecalculateCategories {
            observer.publishAll(from: store)
        } else {
            do {
                try await refreshCategories()
            } catch {
                observer.publishAll(from: store)
            }
        }

        let state = store.snapshot()
        let shouldRefreshRecentExpenses = !state.recentExpenseIDs.isEmpty
        let shouldRefreshExpensesList = state.expensesListPagination.isLoaded
            && !state.expensesListExpenseIDs.isEmpty
        let loadedCategoryIDs = state.categoryPagination.compactMap { element -> String? in
            guard element.value.isLoaded else {
                return nil
            }

            let loadedExpenseIDs = state.categoryExpenseIDs[element.key] ?? []
            return loadedExpenseIDs.isEmpty ? nil : element.key
        }

        if shouldRefreshRecentExpenses {
            try? await refreshRecentExpenses()
        }

        if shouldRefreshExpensesList {
            try? await refreshExpensesFirstPage()
        }

        for categoryID in loadedCategoryIDs {
            try? await refreshCategoryFirstPage(id: categoryID)
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
                fromDate: resolvedCategoryFromDate(for: id),
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
                    fromDate: previousState.categoryFromDates[id]
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
            state.categoriesByID[id] = nil
            state.categoryDetailsByID[id] = nil
            state.categoryOrder.removeAll { $0 == id }
            state.categoryExpenseIDs[id] = nil
            state.categoryPagination[id] = nil
            state.categoryFromDates[id] = nil
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

    func recalculateOverviewCategoriesIfPossible(
        with payload: ProfileCurrencyDidChangePayload
    ) -> Bool {
        var didRecalculateCategories = false
        let previousCurrencyCode = normalizedCurrencyCode(payload.previousCurrencyCode)
        let updatedCurrencyCode = normalizedCurrencyCode(payload.updatedCurrencyCode)

        store.update { state in
            state.preferredCurrencyCode = updatedCurrencyCode

            guard !state.categoryOrder.isEmpty else {
                didRecalculateCategories = true
                return
            }

            guard let previousRateToUsd = rateToUsd(
                for: previousCurrencyCode,
                explicitRateToUsd: payload.previousRateToUsd
            ),
            let updatedRateToUsd = rateToUsd(
                for: updatedCurrencyCode,
                explicitRateToUsd: payload.updatedRateToUsd
            ) else {
                return
            }

            let categories = state.categoryOrder.compactMap { state.categoriesByID[$0] }
            guard categories.count == state.categoryOrder.count else {
                return
            }

            guard categories.allSatisfy({
                isSameCurrency($0.currency, previousCurrencyCode)
            }) else {
                return
            }

            for category in categories {
                let amountInUsd = amountInUsd(
                    amount: category.amount,
                    currency: previousCurrencyCode,
                    rateToUsd: previousRateToUsd
                )
                let updatedAmount = amountFromUsd(
                    amountInUsd: amountInUsd,
                    currency: updatedCurrencyCode,
                    rateToUsd: updatedRateToUsd
                )

                state.categoriesByID[category.id] = MainCategoryCardModel(
                    id: category.id,
                    name: category.name,
                    icon: category.icon,
                    color: category.color,
                    amount: updatedAmount,
                    currency: updatedCurrencyCode
                )
            }

            didRecalculateCategories = true
        }

        return didRecalculateCategories
    }

    func normalizedCurrencyCode(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    func rateToUsd(
        for currencyCode: String,
        explicitRateToUsd: Double?
    ) -> Double? {
        if isSameCurrency(currencyCode, "USD") {
            return 1
        }

        guard let explicitRateToUsd, explicitRateToUsd > .zero else {
            return nil
        }

        return explicitRateToUsd
    }

    func amountInUsd(
        amount: Double,
        currency: String,
        rateToUsd: Double
    ) -> Double {
        if isSameCurrency(currency, "USD") {
            return amount
        }

        return amount * rateToUsd
    }

    func amountFromUsd(
        amountInUsd: Double,
        currency: String,
        rateToUsd: Double
    ) -> Double {
        if isSameCurrency(currency, "USD") {
            return amountInUsd
        }

        guard rateToUsd > .zero else {
            return amountInUsd
        }

        return amountInUsd / rateToUsd
    }

    func isSameCurrency(_ lhs: String, _ rhs: String) -> Bool {
        lhs.compare(rhs, options: [.caseInsensitive]) == .orderedSame
    }

    func makeCategoryModel(
        from category: CategoryDTO,
        monthlyTotals: [String: Double]? = nil
    ) -> MainCategoryCardModel {
        let usdAmount = monthlyTotals?[category.id] ?? category.totalSpentUsd ?? .zero
        let convertedAmount = currencyConversionService.convertUsdAmount(usdAmount)
        return MainCategoryCardModel(
            id: category.id,
            name: localizedCategoryName(from: category.name),
            icon: category.icon,
            color: category.color,
            amount: convertedAmount.amount,
            currency: convertedAmount.currency
        )
    }

    func makeCategoryDetailModel(
        from category: CategoryDTO,
        total: Double?
    ) -> MainCategoryCardModel {
        let usdAmount = total ?? category.totalSpentUsd ?? .zero
        let convertedAmount = currencyConversionService.convertUsdAmount(usdAmount)
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

    func fetchCategoryTotal(
        for categoryID: String,
        fromDate: Date?
    ) async -> Double? {
        guard let summaryService else {
            return nil
        }

        do {
            let response = try await summaryService.getSummaryByCategory(
                id: categoryID,
                parameters: .init(from: fromDate)
            )

            return response.total
        } catch {
            return nil
        }
    }

    func makeCategoryExpensesQueryParameters(
        categoryID: String,
        fromDate: Date?,
        cursor: String?,
        limit: Int
    ) -> ExpensesListQueryParameters {
        return .init(
            category: categoryID,
            from: fromDate,
            cursor: cursor,
            limit: limit
        )
    }

    func resolvedCategoryFromDate(
        for categoryID: String,
        overridingFromDate: Date? = nil
    ) -> Date? {
        if let overridingFromDate {
            return normalizedCategoryFromDate(overridingFromDate)
        }

        let state = store.snapshot()
        if let storedFromDate = state.categoryFromDates[categoryID] {
            return storedFromDate
        }

        return summaryPeriodProvider.map { normalizedCategoryFromDate($0.currentMonthPeriod().from) }
    }

    func normalizedCategoryFromDate(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    func shouldIncludeInCategoryDetails(
        _ expense: MainExpenseModel,
        categoryID: String,
        state: MainFlowDomainState
    ) -> Bool {
        guard expense.category == categoryID else {
            return false
        }

        guard let fromDate = state.categoryFromDates[categoryID] else {
            return true
        }

        return expense.timeOfAdd >= fromDate
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
