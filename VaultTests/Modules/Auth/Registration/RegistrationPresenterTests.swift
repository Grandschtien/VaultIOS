import XCTest
@testable import Vault

@MainActor
final class RegistrationPresenterTests: XCTestCase {
    private var sut: RegistrationPresenter!

    override func setUp() {
        super.setUp()
        sut = RegistrationPresenter(viewModel: .init())
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension RegistrationPresenterTests {
    func testPresentFetchedDataStepOneBuildsPrimaryAndHidesSecondary() {
        sut.presentFetchedData(
            RegistrationFetchData(
                step: .account,
                email: "name@example.com"
            )
        )

        XCTAssertEqual(sut.viewModel.stepLabel.text, L10n.stepNumber(1, 3))
        XCTAssertEqual(sut.viewModel.primaryButton.title, L10n.next)
        XCTAssertTrue(sut.viewModel.isSecondaryButtonHidden)

        guard case let .account(accountViewModel) = sut.viewModel.content else {
            return XCTFail("Expected account step view model")
        }

        XCTAssertEqual(accountViewModel.emailField.text, "name@example.com")
    }
}

extension RegistrationPresenterTests {
    func testPresentFetchedDataStepTwoShowsBackButton() {
        sut.presentFetchedData(
            RegistrationFetchData(
                step: .name,
                name: "Egor"
            )
        )

        XCTAssertEqual(sut.viewModel.stepLabel.text, L10n.stepNumber(2, 3))
        XCTAssertFalse(sut.viewModel.isSecondaryButtonHidden)
        XCTAssertEqual(sut.viewModel.secondaryButton.title, L10n.registrationBack)

        guard case let .name(nameViewModel) = sut.viewModel.content else {
            return XCTFail("Expected name step view model")
        }

        XCTAssertEqual(nameViewModel.nameField.text, "Egor")
    }
}

extension RegistrationPresenterTests {
    func testPresentFetchedDataLoadingDisablesPrimaryButton() {
        sut.presentFetchedData(
            RegistrationFetchData(
                loadingState: .loading,
                step: .currency
            )
        )

        XCTAssertFalse(sut.viewModel.primaryButton.isEnabled)
        XCTAssertTrue(sut.viewModel.primaryButton.isLoading)
    }
}

extension RegistrationPresenterTests {
    func testPresentFetchedDataCurrencyStepBuildsPopularAndOtherSections() {
        sut.presentFetchedData(
            RegistrationFetchData(
                step: .currency,
                selectedCurrencyCode: "USD",
                popularCurrencies: [
                    .init(code: "USD", title: "US Dollar")
                ],
                otherCurrencies: [
                    .init(code: "EUR", title: "Euro")
                ]
            )
        )

        guard case let .currency(currencyViewModel) = sut.viewModel.content else {
            return XCTFail("Expected currency step view model")
        }

        XCTAssertEqual(currencyViewModel.popularRows.count, 1)
        XCTAssertEqual(currencyViewModel.otherRows.count, 1)
        XCTAssertTrue(currencyViewModel.popularRows[0].isSelected)
        XCTAssertEqual(currencyViewModel.otherRows[0].subtitle.text, "EUR")
    }
}
