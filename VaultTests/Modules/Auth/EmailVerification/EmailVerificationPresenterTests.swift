import XCTest
@testable import Vault

@MainActor
final class EmailVerificationPresenterTests: XCTestCase {
    private var sut: EmailVerificationPresenter!

    override func setUp() {
        super.setUp()
        sut = EmailVerificationPresenter(viewModel: .init())
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension EmailVerificationPresenterTests {
    func testPresentFetchedDataIdleBuildsStaticContent() {
        sut.presentFetchedData(
            EmailVerificationFetchData(
                email: "jane@example.com"
            )
        )

        XCTAssertEqual(sut.viewModel.title.text, L10n.emailVerificationTitle)
        XCTAssertEqual(sut.viewModel.subtitle.text, L10n.emailVerificationSubtitle)
        XCTAssertEqual(sut.viewModel.resendPrompt.text, L10n.emailVerificationResendPrompt)
        XCTAssertEqual(sut.viewModel.resendAction.title, L10n.emailVerificationResend.uppercased())
        XCTAssertNil(sut.viewModel.resendAction.countdownLabel)
    }

    func testPresentFetchedDataLoadingDisablesCodeInputAndResend() {
        sut.presentFetchedData(
            EmailVerificationFetchData(
                loadingState: .loading,
                resendAvailableIn: 0
            )
        )

        XCTAssertFalse(sut.viewModel.codeInput.isEnabled)
        XCTAssertFalse(sut.viewModel.resendAction.isEnabled)
    }

    func testPresentFetchedDataErrorShowsInlineErrorState() {
        sut.presentFetchedData(
            EmailVerificationFetchData(
                code: "123456",
                errorMessage: L10n.emailVerificationInvalidCode
            )
        )

        XCTAssertEqual(sut.viewModel.errorLabel?.text, L10n.emailVerificationInvalidCode)
        XCTAssertTrue(sut.viewModel.codeInput.isErrorState)
    }

    func testPresentFetchedDataFormatsResendCountdown() {
        sut.presentFetchedData(
            EmailVerificationFetchData(
                resendAvailableIn: 45
            )
        )

        XCTAssertEqual(sut.viewModel.resendAction.title, L10n.emailVerificationResend.uppercased())
        XCTAssertEqual(sut.viewModel.resendAction.countdownLabel?.text, "0:45")
        XCTAssertFalse(sut.viewModel.resendAction.isEnabled)
    }
}
