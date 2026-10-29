import XCTest
@testable import Vylok

final class CategoryProvidersTests: XCTestCase {
    func testSummaryProviderFetchCategoryMapsResponse() async throws {
        let service = MainCategoriesContractServicingMock()
        service.getCategoryIdReturnValue = .init(
            category: .init(
                id: "cat-1",
                name: "Food",
                icon: "🍔",
                color: "light_orange",
                totalSpent: 123.4,
                currency: "EUR"
            )
        )
        let sut = CategorySummaryProvider(categoriesService: service)

        let category = try await sut.fetchCategory(id: "cat-1")

        XCTAssertEqual(category.id, "cat-1")
        XCTAssertEqual(category.name, "Food")
        XCTAssertEqual(category.icon, "🍔")
        XCTAssertEqual(category.color, "light_orange")
        XCTAssertEqual(category.amount, 123.4)
        XCTAssertEqual(category.currency, "EUR")
        let requestedCategoryIDs = service.getCategoryIdReceivedInvocations
        XCTAssertEqual(requestedCategoryIDs, ["cat-1"])
    }
}

extension CategoryProvidersTests {
    func testSummaryProviderFallsBackToUsdWhenTotalSpentIsMissing() async throws {
        let service = MainCategoriesContractServicingMock()
        service.getCategoryIdReturnValue = .init(
            category: .init(
                id: "cat-1",
                name: "Food",
                icon: "🍔",
                color: "light_orange",
                totalSpentUsd: 19.4,
                currency: "KZT"
            )
        )
        let sut = CategorySummaryProvider(categoriesService: service)

        let category = try await sut.fetchCategory(id: "cat-1")

        XCTAssertEqual(category.amount, 19.4)
        XCTAssertEqual(category.currency, "USD")
    }
}

extension CategoryProvidersTests {
    func testSummaryProviderMapsUnmappedCategoryName() async throws {
        let service = MainCategoriesContractServicingMock()
        service.getCategoryIdReturnValue = .init(
            category: .init(
                id: "cat-1",
                name: "Unmapped",
                icon: "❓",
                color: "light_blue",
                totalSpentUsd: nil
            )
        )
        let sut = CategorySummaryProvider(categoriesService: service)

        let category = try await sut.fetchCategory(id: "cat-1")

        XCTAssertEqual(category.name, L10n.other)
        XCTAssertEqual(category.amount, .zero)
    }
}

extension CategoryProvidersTests {
    func testExpensesProviderFetchPageForwardsCategoryCursorAndLimit() async throws {
        let service = MainExpensesContractServicingMock()
        service.listExpensesParametersReturnValue = .init(
            expenses: [
                .init(
                    id: "exp-1",
                    title: "Coffee",
                    description: nil,
                    amount: 4.5,
                    currency: "USD",
                    category: "cat-1",
                    timeOfAdd: Date(timeIntervalSince1970: 100)
                )
            ],
            nextCursor: "next-1",
            hasMore: true
        )
        let profileStorage = UserProfileStorageServiceProtocolMock()
        profileStorage.loadProfileReturnValue = UserProfileDefaults(
            userId: "user-1",
            email: "user@example.com",
            name: "Test User",
            currency: "EUR",
            language: "en-US",
            currencyRate: 2.0
        )
        let sut = CategoryExpensesProvider(
            expensesService: service,
            currencyConversionService: UserCurrencyConversionService(
                userProfileStorageService: profileStorage
            )
        )

        let page = try await sut.fetchExpensesPage(
            categoryID: "cat-1",
            cursor: "cursor-1",
            limit: 20
        )

        XCTAssertEqual(page.expenses.count, 1)
        XCTAssertEqual(page.expenses.first?.description, "")
        XCTAssertEqual(page.expenses.first?.amount, 2.25)
        XCTAssertEqual(page.expenses.first?.currency, "EUR")
        XCTAssertEqual(page.nextCursor, "next-1")
        XCTAssertTrue(page.hasMore)
        let requestedParameters = service.listExpensesParametersReceivedInvocations
        XCTAssertEqual(
            requestedParameters,
            [.init(category: "cat-1", cursor: "cursor-1", limit: 20)]
        )
    }
}

extension CategoryProvidersTests {
    func testExpensesProviderDeleteForwardsExpenseID() async throws {
        let service = MainExpensesContractServicingMock()
        service.listExpensesParametersReturnValue = .init(
            expenses: [],
            nextCursor: nil,
            hasMore: false
        )
        let sut = CategoryExpensesProvider(
            expensesService: service,
            currencyConversionService: UserCurrencyConversionService(
                userProfileStorageService: UserProfileStorageServiceProtocolMock()
            )
        )

        try await sut.deleteExpense(id: "exp-1")

        let requestedDeleteIDs = service.deleteExpenseIdReceivedInvocations
        XCTAssertEqual(requestedDeleteIDs, ["exp-1"])
    }

    func testExpensesProviderShowsOriginalAmountWhenOriginalCurrencyMatchesPreferredCurrency() async throws {
        let service = MainExpensesContractServicingMock()
        service.listExpensesParametersReturnValue = .init(
            expenses: [
                .init(
                    id: "exp-1",
                    title: "Coffee",
                    description: nil,
                    amount: 2.62,
                    currency: "USD",
                    originalAmount: 200,
                    originalCurrency: "RUB",
                    category: "cat-1",
                    timeOfAdd: Date(timeIntervalSince1970: 100)
                )
            ],
            nextCursor: nil,
            hasMore: false
        )
        let profileStorage = UserProfileStorageServiceProtocolMock()
        profileStorage.loadProfileReturnValue = UserProfileDefaults(
            userId: "user-1",
            email: "user@example.com",
            name: "Test User",
            currency: "RUB",
            language: "ru",
            currencyRate: 76.34
        )
        let sut = CategoryExpensesProvider(
            expensesService: service,
            currencyConversionService: UserCurrencyConversionService(
                userProfileStorageService: profileStorage
            )
        )

        let page = try await sut.fetchExpensesPage(
            categoryID: "cat-1",
            cursor: nil,
            limit: 20
        )

        XCTAssertEqual(page.expenses.first?.amount, 200)
        XCTAssertEqual(page.expenses.first?.currency, "RUB")
    }
}
