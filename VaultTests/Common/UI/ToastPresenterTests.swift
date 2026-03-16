import XCTest
@testable import Vault

@MainActor
final class ToastPresenterTests: XCTestCase {
    private var sut: ToastPresenter!

    override func setUp() {
        super.setUp()
        sut = ToastPresenter(windowProvider: { nil })
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension ToastPresenterTests {
    func testPresentErrorStateBuildsExclamationIcon() {
        sut.present(
            state: .error,
            title: "Error"
        )

        XCTAssertEqual(sut.viewModel.state, .error)
        XCTAssertEqual(sut.viewModel.icon, .sfSymbol(name: "exclamationmark.circle.fill"))
        XCTAssertFalse(sut.viewModel.isButtonVisible)
    }
}

extension ToastPresenterTests {
    func testPresentSuccessStateBuildsWithoutIcon() {
        sut.present(
            state: .success,
            title: "Success"
        )

        XCTAssertEqual(sut.viewModel.state, .success)
        XCTAssertEqual(sut.viewModel.icon, .none)
    }
}

extension ToastPresenterTests {
    func testPresentNeuteralStateNormalizesToNeutralAndUsesInfoIcon() {
        sut.present(
            state: .neuteral,
            title: "Info"
        )

        XCTAssertEqual(sut.viewModel.state, .neutral)
        XCTAssertEqual(sut.viewModel.icon, .sfSymbol(name: "info.circle.fill"))
    }
}

extension ToastPresenterTests {
    func testPresentWithButtonTextAndNopeCommandDoesNotShowButton() {
        sut.present(
            state: .neutral,
            title: "Info",
            buttonText: "Open",
            command: .nope
        )

        XCTAssertFalse(sut.viewModel.isButtonVisible)
        XCTAssertNil(sut.viewModel.buttonText)
        XCTAssertEqual(sut.viewModel.command, .nope)
    }
}

extension ToastPresenterTests {
    func testPresentWithButtonTextAndCommandShowsButton() {
        sut.present(
            state: .neutral,
            title: "Info",
            buttonText: "Open",
            command: .any
        )

        XCTAssertTrue(sut.viewModel.isButtonVisible)
        XCTAssertEqual(sut.viewModel.buttonText, "Open")
    }
}
