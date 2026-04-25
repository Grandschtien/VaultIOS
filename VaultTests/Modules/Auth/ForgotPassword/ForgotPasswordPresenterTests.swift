import XCTest
@testable import Vault

@MainActor
final class ForgotPasswordPresenterTests: XCTestCase {
    private var sut: ForgotPasswordPresenter!

    override func setUp() {
        super.setUp()
        sut = ForgotPasswordPresenter(viewModel: .init())
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testPresentFetchedDataIdleBuildsStaticViewModel() {
        sut.presentFetchedData(.init())

        XCTAssertEqual(sut.viewModel.title.text, L10n.forgotPasswordTitle)
        XCTAssertEqual(sut.viewModel.emailField.placeholder, L10n.emailPlaceholder)
        XCTAssertEqual(sut.viewModel.sendButton.title, L10n.forgotPasswordSend)
        XCTAssertNotEqual(sut.viewModel.closeButton.tapCommand, .nope)
    }

    func testPresentFetchedDataLoadingDisablesInputs() {
        sut.presentFetchedData(.init(loadingState: .loading, email: "name@example.com"))

        XCTAssertFalse(sut.viewModel.closeButton.isEnabled)
        XCTAssertFalse(sut.viewModel.emailField.isEnabled)
        XCTAssertFalse(sut.viewModel.sendButton.isEnabled)
        XCTAssertTrue(sut.viewModel.sendButton.isLoading)
    }

    func testPresentFetchedDataErrorKeepsEnteredEmail() {
        sut.presentFetchedData(.init(email: "name@example.com", emailErrorMessage: L10n.registrationErrorInvalidEmail))

        XCTAssertEqual(sut.viewModel.emailField.text, "name@example.com")
        XCTAssertEqual(sut.viewModel.emailField.helpText, L10n.registrationErrorInvalidEmail)
        XCTAssertFalse(sut.viewModel.sendButton.isLoading)
    }
}
