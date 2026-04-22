import Foundation

protocol MainFlowDomainObserverProtocol: Sendable {
    func subscribeOverview() -> AsyncStream<MainFlowOverviewSnapshot>
    func subscribeCategories() -> AsyncStream<MainFlowCategoriesSnapshot>
    func subscribeCategory(id: String) -> AsyncStream<MainFlowCategorySnapshot>
    func subscribeExpensesList() -> AsyncStream<MainFlowExpensesListSnapshot>
    func currentOverviewSnapshot() -> MainFlowOverviewSnapshot
    func currentCategoriesSnapshot() -> MainFlowCategoriesSnapshot
    func currentCategorySnapshot(id: String) -> MainFlowCategorySnapshot
    func currentExpensesListSnapshot() -> MainFlowExpensesListSnapshot
    func publishAll(from store: MainFlowDomainStoreProtocol)
    func finishAll()
}

final class MainFlowDomainObserver: MainFlowDomainObserverProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private let expenseGrouping: MainExpenseGrouping

    private var overviewSnapshot = MainFlowOverviewSnapshot()
    private var categoriesSnapshot = MainFlowCategoriesSnapshot()
    private var expensesListSnapshot = MainFlowExpensesListSnapshot()
    private var categorySnapshots: [String: MainFlowCategorySnapshot] = [:]

    private var overviewContinuations: [UUID: AsyncStream<MainFlowOverviewSnapshot>.Continuation] = [:]
    private var categoriesContinuations: [UUID: AsyncStream<MainFlowCategoriesSnapshot>.Continuation] = [:]
    private var expensesListContinuations: [UUID: AsyncStream<MainFlowExpensesListSnapshot>.Continuation] = [:]
    private var categoryContinuations: [String: [UUID: AsyncStream<MainFlowCategorySnapshot>.Continuation]] = [:]

    init(expenseGrouping: MainExpenseGrouping) {
        self.expenseGrouping = expenseGrouping
    }

    func subscribeOverview() -> AsyncStream<MainFlowOverviewSnapshot> {
        let token = UUID()

        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            let snapshot = self.lock.withLock {
                self.overviewContinuations[token] = continuation
                return self.overviewSnapshot
            }

            continuation.yield(snapshot)
            continuation.onTermination = { [weak self] _ in
                self?.removeOverviewContinuation(token)
            }
        }
    }

    func subscribeCategories() -> AsyncStream<MainFlowCategoriesSnapshot> {
        let token = UUID()

        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            let snapshot = self.lock.withLock {
                self.categoriesContinuations[token] = continuation
                return self.categoriesSnapshot
            }

            continuation.yield(snapshot)
            continuation.onTermination = { [weak self] _ in
                self?.removeCategoriesContinuation(token)
            }
        }
    }

    func subscribeCategory(id: String) -> AsyncStream<MainFlowCategorySnapshot> {
        let token = UUID()

        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            let snapshot = self.lock.withLock {
                var continuations = self.categoryContinuations[id] ?? [:]
                continuations[token] = continuation
                self.categoryContinuations[id] = continuations
                return self.categorySnapshots[id] ?? MainFlowCategorySnapshot(categoryID: id)
            }

            continuation.yield(snapshot)
            continuation.onTermination = { [weak self] _ in
                self?.removeCategoryContinuation(categoryID: id, token: token)
            }
        }
    }

    func subscribeExpensesList() -> AsyncStream<MainFlowExpensesListSnapshot> {
        let token = UUID()

        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            let snapshot = self.lock.withLock {
                self.expensesListContinuations[token] = continuation
                return self.expensesListSnapshot
            }

            continuation.yield(snapshot)
            continuation.onTermination = { [weak self] _ in
                self?.removeExpensesListContinuation(token)
            }
        }
    }

    func currentOverviewSnapshot() -> MainFlowOverviewSnapshot {
        lock.withLock {
            overviewSnapshot
        }
    }

    func currentCategoriesSnapshot() -> MainFlowCategoriesSnapshot {
        lock.withLock {
            categoriesSnapshot
        }
    }

    func currentCategorySnapshot(id: String) -> MainFlowCategorySnapshot {
        lock.withLock {
            categorySnapshots[id] ?? MainFlowCategorySnapshot(categoryID: id)
        }
    }

    func currentExpensesListSnapshot() -> MainFlowExpensesListSnapshot {
        lock.withLock {
            expensesListSnapshot
        }
    }

    func publishAll(from store: MainFlowDomainStoreProtocol) {
        let state = store.snapshot()
        let nextOverviewSnapshot = makeOverviewSnapshot(from: state)
        let nextCategoriesSnapshot = makeCategoriesSnapshot(from: state)
        let nextExpensesListSnapshot = makeExpensesListSnapshot(from: state)
        let nextCategorySnapshots = makeCategorySnapshots(from: state)

        let payload = lock.withLock { () -> MainFlowPublishPayload in
            overviewSnapshot = nextOverviewSnapshot
            categoriesSnapshot = nextCategoriesSnapshot
            expensesListSnapshot = nextExpensesListSnapshot
            categorySnapshots = nextCategorySnapshots

            return MainFlowPublishPayload(
                overviewSnapshot: nextOverviewSnapshot,
                categoriesSnapshot: nextCategoriesSnapshot,
                expensesListSnapshot: nextExpensesListSnapshot,
                overviewContinuations: Array(overviewContinuations.values),
                categoriesContinuations: Array(categoriesContinuations.values),
                expensesListContinuations: Array(expensesListContinuations.values),
                categoryContinuations: categoryContinuations,
                categorySnapshots: nextCategorySnapshots
            )
        }

        payload.overviewContinuations.forEach {
            $0.yield(payload.overviewSnapshot)
        }
        payload.categoriesContinuations.forEach {
            $0.yield(payload.categoriesSnapshot)
        }
        payload.expensesListContinuations.forEach {
            $0.yield(payload.expensesListSnapshot)
        }

        payload.categoryContinuations.forEach { categoryID, continuations in
            let snapshot = payload.categorySnapshots[categoryID] ?? MainFlowCategorySnapshot(categoryID: categoryID)
            continuations.values.forEach {
                $0.yield(snapshot)
            }
        }
    }

    func finishAll() {
        let payload = lock.withLock { () -> MainFlowFinishPayload in
            overviewSnapshot = .init()
            categoriesSnapshot = .init()
            expensesListSnapshot = .init()
            categorySnapshots = [:]

            let payload = MainFlowFinishPayload(
                overviewContinuations: Array(overviewContinuations.values),
                categoriesContinuations: Array(categoriesContinuations.values),
                expensesListContinuations: Array(expensesListContinuations.values),
                categoryContinuations: categoryContinuations
            )

            overviewContinuations = [:]
            categoriesContinuations = [:]
            expensesListContinuations = [:]
            categoryContinuations = [:]

            return payload
        }

        payload.overviewContinuations.forEach { $0.finish() }
        payload.categoriesContinuations.forEach { $0.finish() }
        payload.expensesListContinuations.forEach { $0.finish() }
        payload.categoryContinuations.values.forEach { continuations in
            continuations.values.forEach { $0.finish() }
        }
    }
}

private extension MainFlowDomainObserver {
    struct MainFlowPublishPayload {
        let overviewSnapshot: MainFlowOverviewSnapshot
        let categoriesSnapshot: MainFlowCategoriesSnapshot
        let expensesListSnapshot: MainFlowExpensesListSnapshot
        let overviewContinuations: [AsyncStream<MainFlowOverviewSnapshot>.Continuation]
        let categoriesContinuations: [AsyncStream<MainFlowCategoriesSnapshot>.Continuation]
        let expensesListContinuations: [AsyncStream<MainFlowExpensesListSnapshot>.Continuation]
        let categoryContinuations: [String: [UUID: AsyncStream<MainFlowCategorySnapshot>.Continuation]]
        let categorySnapshots: [String: MainFlowCategorySnapshot]
    }

    struct MainFlowFinishPayload {
        let overviewContinuations: [AsyncStream<MainFlowOverviewSnapshot>.Continuation]
        let categoriesContinuations: [AsyncStream<MainFlowCategoriesSnapshot>.Continuation]
        let expensesListContinuations: [AsyncStream<MainFlowExpensesListSnapshot>.Continuation]
        let categoryContinuations: [String: [UUID: AsyncStream<MainFlowCategorySnapshot>.Continuation]]
    }

    func makeOverviewSnapshot(from state: MainFlowDomainState) -> MainFlowOverviewSnapshot {
        let categories = orderedCategories(from: state)
        let previousSummary = lock.withLock {
            overviewSnapshot.summary
        }

        return MainFlowOverviewSnapshot(
            summary: makeSummary(
                from: categories,
                explicitSummary: state.overviewSummary,
                preferredCurrencyCode: state.preferredCurrencyCode,
                previousSummary: previousSummary
            ),
            categories: categories,
            expenseGroups: groupedExpenses(with: state.recentExpenseIDs, from: state)
        )
    }

    func makeCategoriesSnapshot(from state: MainFlowDomainState) -> MainFlowCategoriesSnapshot {
        MainFlowCategoriesSnapshot(categories: orderedCategories(from: state))
    }

    func makeExpensesListSnapshot(from state: MainFlowDomainState) -> MainFlowExpensesListSnapshot {
        MainFlowExpensesListSnapshot(
            categories: orderedCategories(from: state).map {
                MainCategoryModel(
                    id: $0.id,
                    name: $0.name,
                    icon: $0.icon,
                    color: $0.color
                )
            },
            expenseGroups: groupedExpenses(with: state.expensesListExpenseIDs, from: state),
            hasMore: state.expensesListPagination.hasMore
        )
    }

    func makeCategorySnapshots(from state: MainFlowDomainState) -> [String: MainFlowCategorySnapshot] {
        let visibleCategoryIDs = Set(state.categoryOrder)
        let loadedCategoryIDs = Set(state.categoryExpenseIDs.keys)
        let subscribedCategoryIDs = lock.withLock {
            Set(categoryContinuations.keys)
        }

        return Dictionary(
            uniqueKeysWithValues: visibleCategoryIDs
                .union(loadedCategoryIDs)
                .union(subscribedCategoryIDs)
                .map { categoryID in
                    (
                        categoryID,
                        MainFlowCategorySnapshot(
                            categoryID: categoryID,
                            period: state.categoryPeriods[categoryID],
                            category: state.categoryDetailsByID[categoryID] ?? state.categoriesByID[categoryID],
                            expenseGroups: groupedExpenses(
                                with: state.categoryExpenseIDs[categoryID] ?? [],
                                from: state
                            ),
                            deletingExpenseIDs: deletingExpenseIDs(for: categoryID, from: state),
                            hasMore: state.categoryPagination[categoryID]?.hasMore ?? false
                        )
                    )
                }
        )
    }

    func orderedCategories(from state: MainFlowDomainState) -> [MainCategoryCardModel] {
        let orderIndexes = Dictionary(
            uniqueKeysWithValues: state.categoryOrder.enumerated().map { index, categoryID in
                (categoryID, index)
            }
        )

        return state.categoryOrder
            .compactMap { state.categoriesByID[$0] }
            .sorted { left, right in
                if left.amount == right.amount {
                    return (orderIndexes[left.id] ?? .zero) < (orderIndexes[right.id] ?? .zero)
                }

                return left.amount > right.amount
            }
    }

    func makeSummary(
        from categories: [MainCategoryCardModel],
        explicitSummary: MainSummaryModel?,
        preferredCurrencyCode: String?,
        previousSummary: MainSummaryModel?
    ) -> MainSummaryModel? {
        if let explicitSummary {
            return explicitSummary
        }

        let resolvedCurrency: String? = if let currencyFromCategories = categories.first?.currency {
            currencyFromCategories
        } else if let currencyFromPreferred = preferredCurrencyCode {
            currencyFromPreferred
        } else {
            previousSummary?.currency
        }

        guard let currency = resolvedCurrency else {
            return nil
        }

        return MainSummaryModel(
            totalAmount: categories.reduce(.zero) { partialResult, category in
                partialResult + category.amount
            },
            currency: currency,
            changePercent: previousSummary?.changePercent ?? .zero
        )
    }

    func groupedExpenses(with ids: [String], from state: MainFlowDomainState) -> [MainExpenseGroupModel] {
        let expenses = ids.compactMap { state.expensesByID[$0] }
        return expenseGrouping.groupExpenses(expenses)
    }

    func deletingExpenseIDs(for categoryID: String, from state: MainFlowDomainState) -> Set<String> {
        Set(
            state.pendingDeletedExpenseIDs.filter { expenseID in
                state.expensesByID[expenseID]?.category == categoryID
            }
        )
    }

    func removeOverviewContinuation(_ token: UUID) {
        lock.withLock {
            overviewContinuations[token] = nil
        }
    }

    func removeCategoriesContinuation(_ token: UUID) {
        lock.withLock {
            categoriesContinuations[token] = nil
        }
    }

    func removeExpensesListContinuation(_ token: UUID) {
        lock.withLock {
            expensesListContinuations[token] = nil
        }
    }

    func removeCategoryContinuation(categoryID: String, token: UUID) {
        lock.withLock {
            var continuations = categoryContinuations[categoryID] ?? [:]
            continuations[token] = nil
            categoryContinuations[categoryID] = continuations.isEmpty ? nil : continuations
        }
    }
}

private extension NSLock {
    func withLock<T>(_ block: () -> T) -> T {
        lock()
        defer { unlock() }
        return block()
    }
}
