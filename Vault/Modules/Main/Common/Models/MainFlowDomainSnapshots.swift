import Foundation

struct MainFlowOverviewSnapshot: Equatable, Sendable {
    let summary: MainSummaryModel?
    let categories: [MainCategoryCardModel]
    let expenseGroups: [MainExpenseGroupModel]

    init(
        summary: MainSummaryModel? = nil,
        categories: [MainCategoryCardModel] = [],
        expenseGroups: [MainExpenseGroupModel] = []
    ) {
        self.summary = summary
        self.categories = categories
        self.expenseGroups = expenseGroups
    }

    var hasContent: Bool {
        summary != nil || !categories.isEmpty || !expenseGroups.isEmpty
    }
}

struct MainFlowCategoriesSnapshot: Equatable, Sendable {
    let categories: [MainCategoryCardModel]

    init(categories: [MainCategoryCardModel] = []) {
        self.categories = categories
    }

    var hasContent: Bool {
        !categories.isEmpty
    }
}

struct MainFlowCategorySnapshot: Equatable, Sendable {
    let categoryID: String
    let category: MainCategoryCardModel?
    let expenseGroups: [MainExpenseGroupModel]
    let deletingExpenseIDs: Set<String>
    let hasMore: Bool

    init(
        categoryID: String,
        category: MainCategoryCardModel? = nil,
        expenseGroups: [MainExpenseGroupModel] = [],
        deletingExpenseIDs: Set<String> = [],
        hasMore: Bool = false
    ) {
        self.categoryID = categoryID
        self.category = category
        self.expenseGroups = expenseGroups
        self.deletingExpenseIDs = deletingExpenseIDs
        self.hasMore = hasMore
    }

    var hasContent: Bool {
        category != nil || !expenseGroups.isEmpty
    }
}

struct MainFlowExpensesListSnapshot: Equatable, Sendable {
    let categories: [MainCategoryModel]
    let expenseGroups: [MainExpenseGroupModel]
    let hasMore: Bool

    init(
        categories: [MainCategoryModel] = [],
        expenseGroups: [MainExpenseGroupModel] = [],
        hasMore: Bool = false
    ) {
        self.categories = categories
        self.expenseGroups = expenseGroups
        self.hasMore = hasMore
    }

    var hasContent: Bool {
        !categories.isEmpty || !expenseGroups.isEmpty
    }
}

struct MainFlowPaginationState: Equatable, Sendable {
    var nextCursor: String?
    var hasMore: Bool
    var isLoaded: Bool

    init(
        nextCursor: String? = nil,
        hasMore: Bool = false,
        isLoaded: Bool = false
    ) {
        self.nextCursor = nextCursor
        self.hasMore = hasMore
        self.isLoaded = isLoaded
    }
}

struct MainFlowDomainState: Equatable, Sendable {
    var preferredCurrencyCode: String?
    var categoriesByID: [String: MainCategoryCardModel]
    var categoryDetailsByID: [String: MainCategoryCardModel]
    var categoryOrder: [String]
    var expensesByID: [String: MainExpenseModel]
    var recentExpenseIDs: [String]
    var expensesListExpenseIDs: [String]
    var expensesListPagination: MainFlowPaginationState
    var categoryExpenseIDs: [String: [String]]
    var categoryPagination: [String: MainFlowPaginationState]
    var categoryFromDates: [String: Date]
    var pendingDeletedExpenseIDs: Set<String>

    init(
        preferredCurrencyCode: String? = nil,
        categoriesByID: [String: MainCategoryCardModel] = [:],
        categoryDetailsByID: [String: MainCategoryCardModel] = [:],
        categoryOrder: [String] = [],
        expensesByID: [String: MainExpenseModel] = [:],
        recentExpenseIDs: [String] = [],
        expensesListExpenseIDs: [String] = [],
        expensesListPagination: MainFlowPaginationState = .init(),
        categoryExpenseIDs: [String: [String]] = [:],
        categoryPagination: [String: MainFlowPaginationState] = [:],
        categoryFromDates: [String: Date] = [:],
        pendingDeletedExpenseIDs: Set<String> = []
    ) {
        self.preferredCurrencyCode = preferredCurrencyCode
        self.categoriesByID = categoriesByID
        self.categoryDetailsByID = categoryDetailsByID
        self.categoryOrder = categoryOrder
        self.expensesByID = expensesByID
        self.recentExpenseIDs = recentExpenseIDs
        self.expensesListExpenseIDs = expensesListExpenseIDs
        self.expensesListPagination = expensesListPagination
        self.categoryExpenseIDs = categoryExpenseIDs
        self.categoryPagination = categoryPagination
        self.categoryFromDates = categoryFromDates
        self.pendingDeletedExpenseIDs = pendingDeletedExpenseIDs
    }
}
