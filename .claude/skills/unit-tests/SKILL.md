---
name: unit-tests
description: Rules and examples for writing Vault unit tests (XCTest) with Sourcery-generated mocks only. Use when the user asks to write, add, update or fix unit tests for presenters, interactors, services, providers or repositories, or runs /unit-tests. Trigger words: тесты, юнит тесты, напиши тесты, покрой тестами, unit tests, write tests.
---

# Writing Vault unit tests

This skill is the single source of the unit testing rules for the project. Apply to any production change. Read `examples.md` next to this file before writing the first test. After a feature is implemented, cover it with the `unit-test-writer` agent, which follows this skill.

## What to test

- Every new service ships with tests in the same change.
- Only presenters, interactors, services, providers, resolvers and repositories.
- Never view controllers, views, view models, factories, Nivelir routers or actions.
- One test case class per production class: `<ClassName>Tests`, placed under `VaultTests/` in the same folder structure as the class under `Vault/` (`Vault/Modules/Auth/Login/LoginInteractor.swift` → `VaultTests/Modules/Auth/Login/LoginInteractorTests.swift`).
- The test target uses synchronized folders: a new file under `VaultTests/` is picked up without touching `project.pbxproj`.

## Mocks: Sourcery only

1. Every dependency of the class under test is a protocol marked `// sourcery: AutoMockable`. If a protocol is missing the annotation, add it in the production file directly above the `protocol` line (keep it below any global-actor attribute such as `@MainActor`).
2. Generate mocks: `/opt/homebrew/bin/sourcery --config .sourcery.yml --disableCache`. The result is `VaultTests/Generated/AutoMockable.generated.swift`; the mock is `<ProtocolName>Mock`.
3. Never edit `VaultTests/Generated/*` by hand. If a mock does not compile or is missing a member, fix the protocol or `Templates/Sourcery/AutoMockable.stencil` and regenerate.
4. Never declare a class, struct or actor that conforms to an app protocol in the test target. No `*Spy`, `*Stub`, `*Fake`, `*Dummy`, `*Mock` types written by hand, including `private` ones inside the test file.
5. `AsyncNetworkClient` (NetworkClient package, generic methods, not mockable by Sourcery): always use the single shared `AsyncNetworkClientMock` from `VaultTests/Support/Mocks/AsyncNetworkClientMock.swift`. Stub the response with `setResponse(json:)` or the error with `nextError`, inspect calls with `capturedTargets`, `onRequest` and `onRequestWithoutResponse`. Never write another `AsyncNetworkClient` double; if the mock lacks something, extend that file, but ask approve for chenges.
6. Any other dependency that is a concrete type (for example `UserDefaults`, `NotificationCenter`) and cannot be hidden behind an app protocol: stop and report it to the caller instead of inventing a fake.

What a generated mock gives you, for `func load(id: String) async throws -> Model`:

| Member | Use |
| --- | --- |
| `loadIdCallsCount`, `loadIdCalled` | how many times it was called |
| `loadIdReceivedArguments`, `loadIdReceivedInvocations` | what it was called with (tuple with labels when there are several parameters) |
| `loadIdReturnValue` | stub of the returned value |
| `loadIdThrowableError` | stub of the thrown error (checked first) |
| `loadIdClosure` | stub with custom behaviour (sequence of values, capturing, suspending) |

The name is the method selector in camel case: `convertExpense(amount:currency:originalAmount:originalCurrency:)` → `convertExpenseAmountCurrencyOriginalAmountOriginalCurrency…`. Look the exact name up in the generated file, never guess it.

## Structure of a test case

```swift
import XCTest
@testable import Vylok

final class FooInteractorTests: XCTestCase {
    private var service: FooServicingMock!
    private var presenter: FooPresentationLogicMock!

    override func setUp() {
        super.setUp()
        service = FooServicingMock()
        presenter = FooPresentationLogicMock()
    }

    override func tearDown() {
        presenter = nil
        service = nil
        super.tearDown()
    }
}

// MARK: - load

extension FooInteractorTests {
    func testLoadWhen…() async {
        // Arrange
        let sut = FooInteractor(service: service, presenter: presenter)
        …
    }
}
```

- `setUp` creates every mock, with the base setup only: the state every test needs (for example a default `ReturnValue` of a non-optional getter that every path reads). No behaviour of a particular scenario goes there.
- The `sut` can be as stored property and but never create it in `setUp`. Every test creates it itself as `let sut = …` at the top of its Arrange block, passing the mocks from the stored properties.
- `tearDown` sets every mock and sut to `nil`, in reverse order of creation.
- Stubs (`…ReturnValue`, `…ThrowableError`, `…Closure`) are set inside the test, in its Arrange block. Never in `setUp`, never in a shared helper.
- The class body holds only properties, `setUp` and `tearDown`. Tests go in extensions, one extension per method or use case under test, each preceded by `// MARK: - <method name>`.
- No `makeSut(...)` helpers: the initializer of the `sut` is written out in each test, so a test that needs another configuration (for example a different context) just passes other values.
- A mock the `sut` keeps `weak` (for example the presenter's `handler`) stays a stored property created in `setUp`, otherwise it is released before the call.
- Annotate the class with `@MainActor` only when the class under test is `@MainActor` (presenters).

## Arrange, Act, Assert

Every test has exactly three blocks, separated by an empty line and marked with comments:

```swift
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
}
```

- Arrange: creation of the `sut`, stubs and input data. Calls to the `sut` that only bring it into the needed state (for example `handleEmailDidChange` before `handleTapSend`) also belong here.
- Act: one call of the method under test. Store its result in a local constant.
- Assert: only assertions. No calls of the `sut`.
- Every test has an Arrange block, at least with the creation of the `sut`.

## Comparing results

- Compare the whole output model with one `XCTAssertEqual(result, expected)`, where `expected` is a fully constructed value. Never assert field by field (`result.id`, `result.count`, `result.first?.amount`).
- Same for collections: compare the whole array, not `.count` or `.first`.
- Same for what the dependencies received: `XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations, [expected1, expected2])` checks both the values and the call count.
- A method with several parameters records a labelled tuple, which is not `Equatable`: `let arguments = try XCTUnwrap(mock.…ReceivedArguments)` and `XCTAssertTrue(arguments == (amount: 24, currency: "USD"))` with every element of the tuple.
- When several tests of one case expect the same large model with a few varying values, a builder of the expected value is allowed in a `private extension` of the test case. It takes only the varying inputs and writes every other value out; it never calls the production code that builds the model.
- If the model is not `Equatable`, add `Equatable` to its declaration in the production file. That and `// sourcery: AutoMockable` are the only production changes this skill allows. If it cannot be `Equatable` (contains closures), report it to the caller.
- Commands (`Command`, `CommandOf`) are compared by identity. In presenter tests build the expected view model with the commands taken from the actual one, and verify each command separately: execute it with `executeAsync()` / the input and assert the call on the handler mock. See example 3.
- For an expected error use `XCTAssertThrowsError` for sync code and `Result` for async code (see `TestError` and `Result.init(catching:) async` in `VaultTests/Support/`), and compare the error itself with `XCTAssertEqual`.

## Async code

- Wait for async results with `XCTestExpectation` and `await fulfillment(of:timeout:)`, never with `Task.yield()` or `Task.sleep`.
- Create the expectation before the call that triggers the work, fulfil it from the mock (`…Closure`) when the expected call arrives, and set `assertForOverFulfill = false` when the call can repeat.
- To check that something does not happen, use an inverted expectation (`isInverted = true`) with a short timeout.

## Test data

- Simple values (strings, numbers, one small DTO) are written inline in the test.
- Complex data (nested DTOs, lists, models with many fields, data reused by several test cases) goes into a fixture factory in the test target: `VaultTests/Support/Fixtures/<Feature>/<Model>Fixtures.swift`, `enum <Model>Fixtures` with static `make…` functions whose parameters have defaults, so a test overrides only what matters to it. Fixtures build values only; they never conform to app protocols and never hold state.
- Reuse an existing fixture before creating a new one: `ls VaultTests/Support/Fixtures`.

## Which cases to cover

For each public method under test:
- The happy path.
- Each distinct error: every `throw` in the method, every error a dependency can throw that the method handles differently, every validation failure. If the method catches all errors the same way, one error test is enough.
- Each branch that changes the output: early `guard` returns, empty input, `nil` optional dependencies (for example `analytics: nil`), limits and boundaries the code checks explicitly (`prefix(5)` → feed more than 5).

Do not over-test: keep the number of tests per test case minimal, one test per distinct case.
- No test per trivial getter, no test that only repeats another one with different literals.
- No checks of internal implementation details that are not visible through the dependencies or the output.
- No test that asserts a mock was not called unless "not called" is the point of the case (for example the router must not close on error).

## Naming

`test<Method>When<Condition><ExpectedOutcome>`: `testHandleTapSendWhenEmailIsEmptyShowsFillFieldError`. Without a condition: `testFetchDataPresentsInitialState`.

## Running

Build and run only the affected test classes:

```bash
env PATH=/usr/bin:/bin:/usr/sbin:/sbin xcodebuild test \
  -project Vault.xcodeproj -scheme Vylok \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:VaultTests/FooInteractorTests \
  -quiet 2>&1 | tail -80
```

The trimmed `PATH` is required: with Homebrew on `PATH` the SwiftGen phase breaks `Assets.generated.swift`. The Sourcery phase of `VaultTests` adds Homebrew itself and regenerates mocks. If asset errors appear anyway, restore with `swiftgen config run --config swiftgen.yml` and `swiftgen config run --config swiftgen.widget.yml`.

Fix every failure and every Swift concurrency warning in the test files before finishing. A failing test is fixed in the test only when the test is wrong; when the production code is wrong, report it instead of changing the expectation.
