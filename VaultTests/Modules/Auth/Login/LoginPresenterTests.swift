import XCTest
@testable import Vault

@MainActor
final class LoginPresenterTests: XCTestCase {
    private var sut: LoginPresenter!

    override func setUp() {
        super.setUp()
        sut = LoginPresenter(viewModel: .init())
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension LoginPresenterTests {
    func testPresentFetchedDataIdleBuildsExpectedStaticViewModel() {
        sut.presentFetchedData(
            LoginFetchData(
                loadingState: .idle,
                email: "",
                password: ""
            )
        )

        XCTAssertEqual(sut.viewModel.title.text, L10n.vault)
        XCTAssertEqual(sut.viewModel.subtitle.text, L10n.smartExpenseTrackingForYourDigitalLifestyle)
        XCTAssertEqual(sut.viewModel.emailField.placeholder, L10n.emailPlaceholder)
        XCTAssertEqual(sut.viewModel.passwordField.additionalLabelText, L10n.forgot)
        XCTAssertEqual(sut.viewModel.signInButton.height, 64)
        XCTAssertEqual(sut.viewModel.signInButton.cornerRadius, 32)
    }
}

extension LoginPresenterTests {
    func testPresentFetchedDataLoadingDisablesSignInButton() {
        sut.presentFetchedData(
            LoginFetchData(
                loadingState: .loading,
                email: "name@example.com",
                password: "12345678"
            )
        )

        XCTAssertFalse(sut.viewModel.signInButton.isEnabled)
        XCTAssertTrue(sut.viewModel.signInButton.isLoading)
    }
}

extension LoginPresenterTests {
    func testPresentFetchedDataFailedKeepsEnteredCredentials() {
        sut.presentFetchedData(
            LoginFetchData(
                loadingState: .failed(StubError.any),
                email: "name@example.com",
                password: "12345678"
            )
        )

        XCTAssertEqual(sut.viewModel.emailField.text, "name@example.com")
        XCTAssertEqual(sut.viewModel.passwordField.text, "12345678")
        XCTAssertNotNil(sut.viewModel.passwordField.helpText)
        XCTAssertFalse(sut.viewModel.signInButton.isLoading)
    }
}

private extension LoginPresenterTests {
    enum StubError: Error {
        case any
    }
}
