import XCTest
@testable import Vylok

final class ForgotPasswordInteractorTests: XCTestCase {
    private var passwordRestorationService: PasswordRestorationContractServicingMock!
    private var presenter: ForgotPasswordPresentationLogicMock!
    private var router: ForgotPasswordRoutingLogicMock!
    private var analytics: ForgotPasswordAnalyticsTrackingMock!
    private var sut: ForgotPasswordInteractor!

    override func setUp() {
        super.setUp()
        passwordRestorationService = PasswordRestorationContractServicingMock()
        presenter = ForgotPasswordPresentationLogicMock()
        router = ForgotPasswordRoutingLogicMock()
        analytics = ForgotPasswordAnalyticsTrackingMock()
        sut = ForgotPasswordInteractor(
            passwordRestorationService: passwordRestorationService,
            presenter: presenter,
            router: router,
            context: .init(email: "name@example.com"),
            analytics: analytics
        )
    }

    override func tearDown() {
        sut = nil
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

// MARK: - handleTapClose

extension ForgotPasswordInteractorTests {
    func testHandleTapCloseClosesScreen() async {
        // Act
        await sut.handleTapClose()

        // Assert
        XCTAssertEqual(router.closeCallsCount, 1)
    }
}
