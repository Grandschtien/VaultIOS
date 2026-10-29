import XCTest
@testable import Vylok

final class MainExpensesProviderTests: XCTestCase {
    private var expensesService: MainExpensesContractServicingMock!
    private var currencyConversionService: UserCurrencyConvertingMock!

    override func setUp() {
        super.setUp()
        expensesService = MainExpensesContractServicingMock()
        currencyConversionService = UserCurrencyConvertingMock()
    }

    override func tearDown() {
        currencyConversionService = nil
        expensesService = nil
        super.tearDown()
    }
}

// MARK: - fetchExpenses

extension MainExpensesProviderTests {
    func testFetchExpensesWhenServiceReturnsMoreThanLimitReturnsFirstFiveConverted() async throws {
        // Arrange
        let sut = MainExpensesProvider(
            expensesService: expensesService,
            currencyConversionService: currencyConversionService
        )
        expensesService.listExpensesParametersReturnValue = ExpenseDTOFixtures.makeListResponse(
            expenses: ExpenseDTOFixtures.makeExpenses(count: 7),
            nextCursor: "cursor-1",
            hasMore: true
        )
        currencyConversionService.convertExpenseAmountCurrencyOriginalAmountOriginalCurrencyReturnValue =
            UserCurrencyAmount(amount: 10, currency: "EUR")

        // Act
        let expenses = try await sut.fetchExpenses()

        // Assert
        XCTAssertEqual(
            expensesService.listExpensesParametersReceivedInvocations,
            [ExpensesListQueryParameters(limit: 5)]
        )
        XCTAssertEqual(
            expenses,
            (1...5).map { index in
                MainExpenseModel(
                    id: "expense-\(index)",
                    title: "Expense \(index)",
                    description: "Latte",
                    amount: 10,
                    currency: "EUR",
                    category: "food",
                    timeOfAdd: ExpenseDTOFixtures.timeOfAdd
                )
            }
        )
    }

    func testFetchExpensesWhenDescriptionIsNilPassesOriginalAmountAndMapsEmptyDescription() async throws {
        // Arrange
        let sut = MainExpensesProvider(
            expensesService: expensesService,
            currencyConversionService: currencyConversionService
        )
        expensesService.listExpensesParametersReturnValue = ExpenseDTOFixtures.makeListResponse(
            expenses: [
                ExpenseDTOFixtures.makeExpense(
                    description: nil,
                    amount: 24,
                    currency: "USD",
                    originalAmount: 2_000,
                    originalCurrency: "RUB"
                )
            ]
        )
        currencyConversionService.convertExpenseAmountCurrencyOriginalAmountOriginalCurrencyReturnValue =
            UserCurrencyAmount(amount: 2_000, currency: "RUB")

        // Act
        let expenses = try await sut.fetchExpenses()

        // Assert
        let conversionArguments = try XCTUnwrap(
            currencyConversionService.convertExpenseAmountCurrencyOriginalAmountOriginalCurrencyReceivedArguments
        )
        XCTAssertTrue(
            conversionArguments == (amount: 24, currency: "USD", originalAmount: 2_000, originalCurrency: "RUB")
        )
        XCTAssertEqual(
            expenses,
            [
                MainExpenseModel(
                    id: "expense-1",
                    title: "Coffee",
                    description: "",
                    amount: 2_000,
                    currency: "RUB",
                    category: "food",
                    timeOfAdd: ExpenseDTOFixtures.timeOfAdd
                )
            ]
        )
    }

    func testFetchExpensesWhenServiceFailsRethrowsError() async {
        // Arrange
        let sut = MainExpensesProvider(
            expensesService: expensesService,
            currencyConversionService: currencyConversionService
        )
        expensesService.listExpensesParametersThrowableError = TestError.any

        // Act
        let result = await Result { try await sut.fetchExpenses() }

        // Assert
        XCTAssertEqual(result.failure as? TestError, .any)
        XCTAssertFalse(currencyConversionService.convertExpenseAmountCurrencyOriginalAmountOriginalCurrencyCalled)
    }
}
