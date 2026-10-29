# Examples

All examples use real Vault classes and real generated mocks. Before using a mock member, check its exact name in `VaultTests/Generated/AutoMockable.generated.swift`.

## 1. Interactor: every error path, stubs inside the test

`Vault/Modules/Auth/ForgotPassword/ForgotPasswordInteractor.swift`. `handleTapSend` has four outcomes: empty email, invalid email, service error, success. Each one is a test; the double-tap guard is not covered because it is not reachable through the handler without suspending the service, which would only test Swift concurrency.

Production change required by the skill: `ForgotPasswordFetchData` gets `Equatable` so the presented data can be compared as a whole:

```swift
struct ForgotPasswordFetchData: Equatable, Sendable {
```

```swift
import XCTest
@testable import Vylok

final class ForgotPasswordInteractorTests: XCTestCase {
    private var passwordRestorationService: PasswordRestorationContractServicingMock!
    private var presenter: ForgotPasswordPresentationLogicMock!
    private var router: ForgotPasswordRoutingLogicMock!
    private var analytics: ForgotPasswordAnalyticsTrackingMock!

    override func setUp() {
        super.setUp()
        passwordRestorationService = PasswordRestorationContractServicingMock()
        presenter = ForgotPasswordPresentationLogicMock()
        router = ForgotPasswordRoutingLogicMock()
        analytics = ForgotPasswordAnalyticsTrackingMock()
    }

    override func tearDown() {
        analytics = nil
        router = nil
        presenter = nil
        passwordRestorationService = nil
        super.tearDown()
    }
}

// MARK: - fetchData

extension ForgotPasswordInteractorTests {
    func testFetchDataPresentsEmailFromContextAndTracksScreenOpen() async {
        // Arrange
        let sut = ForgotPasswordInteractor(
            passwordRestorationService: passwordRestorationService,
            presenter: presenter,
            router: router,
            context: .init(email: "name@example.com"),
            analytics: analytics
        )

        // Act
        await sut.fetchData()

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [ForgotPasswordFetchData(loadingState: .idle, email: "name@example.com")]
        )
        XCTAssertEqual(analytics.trackScreenOpenCallsCount, 1)
    }
}

// MARK: - handleTapSend

extension ForgotPasswordInteractorTests {
    func testHandleTapSendWhenEmailIsValidRequestsResetAndCloses() async {
        // Arrange
        let sut = ForgotPasswordInteractor(
            passwordRestorationService: passwordRestorationService,
            presenter: presenter,
            router: router,
            context: .init(email: "name@example.com"),
            analytics: analytics
        )
        await sut.handleEmailDidChange(" name@example.com ")

        // Act
        await sut.handleTapSend()

        // Assert
        XCTAssertEqual(
            passwordRestorationService.requestPasswordResetReceivedInvocations,
            [ForgotPasswordRequestDTO(email: "name@example.com")]
        )
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                ForgotPasswordFetchData(loadingState: .loading, email: " name@example.com "),
                ForgotPasswordFetchData(loadingState: .loaded, email: " name@example.com ")
            ]
        )
        XCTAssertEqual(router.presentSuccessWithReceivedInvocations, [L10n.forgotPasswordSuccessMessage])
        XCTAssertEqual(router.closeCallsCount, 1)
        XCTAssertEqual(analytics.trackForgotPasswordSuccessCallsCount, 1)
    }

    func testHandleTapSendWhenEmailIsEmptyShowsFillFieldError() async {
        // Arrange
        let sut = ForgotPasswordInteractor(
            passwordRestorationService: passwordRestorationService,
            presenter: presenter,
            router: router,
            context: .init(email: "name@example.com"),
            analytics: analytics
        )
        await sut.handleEmailDidChange("   ")

        // Act
        await sut.handleTapSend()

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [ForgotPasswordFetchData(loadingState: .idle, email: "   ", emailErrorMessage: L10n.commonFillField)]
        )
        XCTAssertFalse(passwordRestorationService.requestPasswordResetCalled)
    }

    func testHandleTapSendWhenEmailIsInvalidShowsInvalidEmailError() async {
        // Arrange
        let sut = ForgotPasswordInteractor(
            passwordRestorationService: passwordRestorationService,
            presenter: presenter,
            router: router,
            context: .init(email: "name@example.com"),
            analytics: analytics
        )
        await sut.handleEmailDidChange("name@")

        // Act
        await sut.handleTapSend()

        // Assert
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                ForgotPasswordFetchData(
                    loadingState: .idle,
                    email: "name@",
                    emailErrorMessage: L10n.registrationErrorInvalidEmail
                )
            ]
        )
        XCTAssertFalse(passwordRestorationService.requestPasswordResetCalled)
    }

    func testHandleTapSendWhenServiceFailsPresentsErrorAndStaysOpen() async {
        // Arrange
        let sut = ForgotPasswordInteractor(
            passwordRestorationService: passwordRestorationService,
            presenter: presenter,
            router: router,
            context: .init(email: "name@example.com"),
            analytics: analytics
        )
        passwordRestorationService.requestPasswordResetThrowableError = TestError.any

        // Act
        await sut.handleTapSend()

        // Assert
        let errorDescription = TestError.any.localizedDescription
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations,
            [
                ForgotPasswordFetchData(loadingState: .loading, email: "name@example.com"),
                ForgotPasswordFetchData(
                    loadingState: .failed(.undelinedError(description: errorDescription)),
                    email: "name@example.com"
                )
            ]
        )
        XCTAssertEqual(router.presentErrorWithReceivedInvocations, [errorDescription])
        XCTAssertFalse(router.closeCalled)
        XCTAssertEqual(analytics.trackForgotPasswordFailureReceivedInvocations as? [TestError], [.any])
    }
}
```

What to notice:
- `setUp` only creates mocks. Each test creates its own `sut` at the top of Arrange; the error stub lives in the test that needs it.
- The invalid-email test does not stub the service: it must not be called, and `requestPasswordResetCalled` proves it.
- `presentFetchedDataReceivedInvocations` is compared as a whole array: values, order and count in one assertion.
- `router.closeCalled` is asserted as `false` only in the error test, where "the screen stays open" is the point.

## 2. Provider: return-value stubs, fixtures, boundary and rethrow

`Vault/Modules/Main/Main/Services/Providers/MainExpensesProvider.swift`. Its input is a list of nested DTOs, so the DTOs come from a fixture factory.

Fixture factory, `VaultTests/Support/Fixtures/Main/ExpenseDTOFixtures.swift`:

```swift
import Foundation
@testable import Vylok

enum ExpenseDTOFixtures {
    static let timeOfAdd = Date(timeIntervalSince1970: 1_700_000_000)

    static func makeExpense(
        id: String = "expense-1",
        title: String = "Coffee",
        description: String? = "Latte",
        amount: Double = 4.5,
        currency: String = "USD",
        originalAmount: Double? = nil,
        originalCurrency: String? = nil,
        category: String = "food",
        timeOfAdd: Date = timeOfAdd
    ) -> ExpenseDTO {
        ExpenseDTO(
            id: id,
            title: title,
            description: description,
            amount: amount,
            currency: currency,
            originalAmount: originalAmount,
            originalCurrency: originalCurrency,
            category: category,
            timeOfAdd: timeOfAdd
        )
    }

    static func makeExpenses(count: Int) -> [ExpenseDTO] {
        (1...count).map { makeExpense(id: "expense-\($0)", title: "Expense \($0)") }
    }

    static func makeListResponse(
        expenses: [ExpenseDTO] = [makeExpense()],
        nextCursor: String? = nil,
        hasMore: Bool = false
    ) -> ExpensesListResponseDTO {
        ExpensesListResponseDTO(expenses: expenses, nextCursor: nextCursor, hasMore: hasMore)
    }
}
```

Test case:

```swift
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
```

What to notice:
- The 7 → 5 test covers the explicit `prefix(5)` boundary; no separate tests for 0, 1 or 5 items.
- The expected output is a full `[MainExpenseModel]`, not `expenses.count` and `expenses.first?.amount`.
- A method with several parameters records a labelled tuple. Tuples are not `Equatable`, so unwrap it and compare the whole tuple with `==`.
- The async error goes through `Result { … }` (`VaultTests/Support/Result+Async.swift`), so Act and Assert stay separate.

## 3. Presenter: whole view model and command routing

`Vault/Modules/Auth/ForgotPassword/ForgotPasswordPresenter.swift`. Commands are compared by identity, so the expected view model takes the commands from the actual one, and each command is checked by executing it against the handler mock.

```swift
import XCTest
@testable import Vylok

@MainActor
final class ForgotPasswordPresenterTests: XCTestCase {
    private var handler: ForgotPasswordHandlerMock!

    override func setUp() {
        super.setUp()
        handler = ForgotPasswordHandlerMock()
    }

    override func tearDown() {
        handler = nil
        super.tearDown()
    }
}

// MARK: - presentFetchedData

extension ForgotPasswordPresenterTests {
    func testPresentFetchedDataWhenIdleBuildsEnabledViewModel() {
        // Arrange
        let sut = ForgotPasswordPresenter(viewModel: .init())
        sut.handler = handler
        let data = ForgotPasswordFetchData(loadingState: .idle, email: "name@example.com")

        // Act
        sut.presentFetchedData(data)

        // Assert
        XCTAssertEqual(
            sut.viewModel,
            makeExpectedViewModel(from: sut.viewModel, email: "name@example.com", emailErrorMessage: nil, isLoading: false)
        )
    }

    func testPresentFetchedDataWhenLoadingDisablesControlsAndShowsLoader() {
        // Arrange
        let sut = ForgotPasswordPresenter(viewModel: .init())
        sut.handler = handler
        let data = ForgotPasswordFetchData(
            loadingState: .loading,
            email: "name@",
            emailErrorMessage: L10n.registrationErrorInvalidEmail
        )

        // Act
        sut.presentFetchedData(data)

        // Assert
        XCTAssertEqual(
            sut.viewModel,
            makeExpectedViewModel(
                from: sut.viewModel,
                email: "name@",
                emailErrorMessage: L10n.registrationErrorInvalidEmail,
                isLoading: true
            )
        )
    }
}

// MARK: - Commands

extension ForgotPasswordPresenterTests {
    func testSendButtonTapCommandCallsHandleTapSend() async {
        // Arrange
        let sut = ForgotPasswordPresenter(viewModel: .init())
        sut.handler = handler
        sut.presentFetchedData(.init())

        // Act
        await sut.viewModel.sendButton.tapCommand.executeAsync()

        // Assert
        XCTAssertEqual(handler.handleTapSendCallsCount, 1)
    }

    func testEmailFieldTextCommandCallsHandleEmailDidChange() async {
        // Arrange
        let sut = ForgotPasswordPresenter(viewModel: .init())
        sut.handler = handler
        sut.presentFetchedData(.init())
        let handled = expectation(description: "handleEmailDidChange")
        handler.handleEmailDidChangeClosure = { _ in handled.fulfill() }

        // Act
        sut.viewModel.emailField.onTextDidChanged?.execute("name@example.com")

        // Assert
        await fulfillment(of: [handled], timeout: 1)
        XCTAssertEqual(handler.handleEmailDidChangeReceivedInvocations, ["name@example.com"])
    }
}

private extension ForgotPasswordPresenterTests {
    func makeExpectedViewModel(
        from actual: ForgotPasswordViewModel,
        email: String,
        emailErrorMessage: String?,
        isLoading: Bool
    ) -> ForgotPasswordViewModel {
        ForgotPasswordViewModel(
            closeButton: .init(isEnabled: !isLoading, tapCommand: actual.closeButton.tapCommand),
            title: .init(
                text: L10n.forgotPasswordTitle,
                font: Typography.typographyBold26,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .left,
                numberOfLines: .zero,
                lineBreakMode: .byWordWrapping
            ),
            emailField: .init(
                text: email,
                placeholder: L10n.emailPlaceholder,
                titleText: L10n.emailAddress,
                leftIcon: actual.emailField.leftIcon,
                helpText: emailErrorMessage,
                helpTextColor: Asset.Colors.errorColor.color,
                isEnabled: !isLoading,
                onTextDidChanged: actual.emailField.onTextDidChanged,
                onReturn: actual.emailField.onReturn
            ),
            sendButton: .init(
                title: L10n.forgotPasswordSend,
                titleColor: Asset.Colors.textAndIconPrimaryInverted.color,
                backgroundColor: Asset.Colors.interactiveElemetsPrimary.color,
                font: Typography.typographyBold18,
                isEnabled: !isLoading,
                isLoading: isLoading,
                tapCommand: actual.sendButton.tapCommand,
                height: 64,
                cornerRadius: 32
            )
        )
    }
}
```

What to notice:
- `handler` is a stored property created in `setUp`: the presenter keeps it `weak`, so a local mock would be released before the command runs. The presenter itself is created in each test.
- The builder of the expected value lives in a `private extension` of the test case and takes only the inputs that vary. It receives the actual view model as a parameter instead of reading a stored `sut`, and copies only identity-compared values (commands) and system images from the actual view model; every text, color, font and flag is written out.
- `CommandOf` has no async execute, so the test stubs `…Closure` to fulfil an expectation, inside the test.

## 4. Do and don't

Don't: hand-written spy, `sut` and stub in `setUp`, partial assertions, mixed blocks.

```swift
final class MainExpensesProviderTests: XCTestCase {
    override func setUp() {
        super.setUp()
        sut = MainExpensesProvider(expensesService: expensesService, currencyConversionService: currencyConversionService) // sut in setUp
        expensesService.listExpensesParametersReturnValue = .init(expenses: [], nextCursor: nil, hasMore: false) // scenario stub in setUp
    }

    func testFetch() async throws {
        let expenses = try await sut.fetchExpenses()
        XCTAssertEqual(expenses.count, 5)                                // partial
        XCTAssertEqual(expenses.first?.currency, "EUR")                  // partial
        let more = try await sut.fetchExpenses()                         // second Act
        XCTAssertEqual(more.count, 5)
    }
}

private final class ExpensesServiceSpy: MainExpensesContractServicing { … } // forbidden, blocked by the hook
```

Do: `MainExpensesContractServicingMock` from Sourcery, `let sut = …` and the stub inside the test, one Act, one `XCTAssertEqual` with the full expected array (example 2).
