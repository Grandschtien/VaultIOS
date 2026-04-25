import XCTest
@testable import Vault

@MainActor
final class ForgotPasswordInteractorTests: XCTestCase {
    func testFetchDataPresentsInitialState() async {
        let presenter = ForgotPasswordPresenterSpy()
        await makeSut(presenter: presenter).fetchData()
        XCTAssertEqual(presenter.presentedData.last?.loadingState, .idle)
        XCTAssertEqual(presenter.presentedData.last?.email, "")
    }

    func testHandleTapSendWithEmptyEmailShowsValidationError() async {
        let presenter = ForgotPasswordPresenterSpy()
        let router = ForgotPasswordRouterSpy()
        await makeSut(presenter: presenter, router: router).handleTapSend()
        XCTAssertEqual(presenter.presentedData.last?.emailErrorMessage, L10n.commonFillField)
        XCTAssertTrue(router.successMessages.isEmpty)
        XCTAssertEqual(router.closeCallsCount, 0)
    }

    func testHandleTapSendWithInvalidEmailShowsValidationError() async {
        let presenter = ForgotPasswordPresenterSpy()
        let router = ForgotPasswordRouterSpy()
        let sut = makeSut(presenter: presenter, router: router)
        await sut.handleEmailDidChange("name")
        await sut.handleTapSend()
        XCTAssertEqual(presenter.presentedData.last?.emailErrorMessage, L10n.registrationErrorInvalidEmail)
        XCTAssertTrue(router.successMessages.isEmpty)
        XCTAssertEqual(router.closeCallsCount, 0)
    }

    func testHandleTapSendWithValidEmailRequestsResetAndShowsSuccess() async {
        let presenter = ForgotPasswordPresenterSpy()
        let router = ForgotPasswordRouterSpy()
        let service = PasswordRestorationContractServiceSpy()
        let sut = makeSut(
            passwordRestorationService: service,
            presenter: presenter,
            router: router
        )
        await sut.handleEmailDidChange("  name@example.com  ")
        await sut.handleTapSend()

        XCTAssertEqual(await service.requestedEmails(), ["name@example.com"])
        XCTAssertEqual(presenter.presentedData.map(\.loadingState), [.loading, .loaded])
        XCTAssertEqual(router.successMessages, [L10n.forgotPasswordSuccessMessage])
        XCTAssertEqual(router.closeCallsCount, 1)
    }

    func testHandleTapSendWhenServiceFailsPresentsErrorAndDoesNotClose() async {
        let presenter = ForgotPasswordPresenterSpy()
        let router = ForgotPasswordRouterSpy()
        let service = PasswordRestorationContractServiceSpy()
        service.nextRequestPasswordResetError = StubError.any
        let sut = makeSut(
            passwordRestorationService: service,
            presenter: presenter,
            router: router
        )

        await sut.handleEmailDidChange("name@example.com")
        await sut.handleTapSend()

        XCTAssertEqual(
            presenter.presentedData.map(\.loadingState),
            [.loading, .failed(.undelinedError(description: StubError.any.localizedDescription))]
        )
        XCTAssertEqual(router.errors, [StubError.any.localizedDescription])
        XCTAssertTrue(router.successMessages.isEmpty)
        XCTAssertEqual(router.closeCallsCount, 0)
    }

    func testHandleTapCloseClosesScreen() async {
        let router = ForgotPasswordRouterSpy()
        await makeSut(router: router).handleTapClose()
        XCTAssertEqual(router.closeCallsCount, 1)
    }
}

private extension ForgotPasswordInteractorTests {
    @MainActor
    func makeSut(
        passwordRestorationService: PasswordRestorationContractServicing? = nil,
        presenter: ForgotPasswordPresentationLogic? = nil,
        router: ForgotPasswordRoutingLogic? = nil
    ) -> ForgotPasswordInteractor {
        ForgotPasswordInteractor(
            passwordRestorationService: passwordRestorationService ?? PasswordRestorationContractServiceSpy(),
            presenter: presenter ?? ForgotPasswordPresenterSpy(),
            router: router ?? ForgotPasswordRouterSpy()
        )
    }
}

@MainActor
private final class ForgotPasswordPresenterSpy: ForgotPasswordPresentationLogic {
    private(set) var presentedData: [ForgotPasswordFetchData] = []
    func presentFetchedData(_ data: ForgotPasswordFetchData) { presentedData.append(data) }
}

@MainActor
private final class ForgotPasswordRouterSpy: ForgotPasswordRoutingLogic {
    private(set) var closeCallsCount = 0
    private(set) var successMessages: [String] = []
    private(set) var errors: [String] = []

    func close() { closeCallsCount += 1 }
    func presentSuccess(with text: String) { successMessages.append(text) }
    func presentError(with text: String) { errors.append(text) }
}

private final class PasswordRestorationContractServiceSpy: PasswordRestorationContractServicing, @unchecked Sendable {
    var nextRequestPasswordResetError: Error?

    private let lock = NSLock()
    private var _requestedEmails: [String] = []

    func requestPasswordReset(_ request: ForgotPasswordRequestDTO) async throws {
        lock.withLock {
            _requestedEmails.append(request.email)
        }

        if let nextRequestPasswordResetError {
            throw nextRequestPasswordResetError
        }
    }

    func resetPassword(_ request: ResetPasswordRequestDTO) async throws {}

    func requestedEmails() async -> [String] {
        lock.withLock { _requestedEmails }
    }
}

private extension ForgotPasswordInteractorTests {
    enum StubError: LocalizedError {
        case any

        var errorDescription: String? {
            "stub-error"
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
