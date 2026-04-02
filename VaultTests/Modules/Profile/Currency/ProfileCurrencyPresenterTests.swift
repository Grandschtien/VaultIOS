import XCTest
@testable import Vault

@MainActor
final class ProfileCurrencyPresenterTests: XCTestCase {
    private var sut: ProfileCurrencyPresenter!
    private var handler: ProfileCurrencyHandlerSpy!

    override func setUp() {
        super.setUp()
        handler = ProfileCurrencyHandlerSpy()
        sut = ProfileCurrencyPresenter(viewModel: .init())
        sut.handler = handler
    }

    override func tearDown() {
        handler = nil
        sut = nil
        super.tearDown()
    }
}

extension ProfileCurrencyPresenterTests {
    func testPresentFetchedDataBuildsSelectedFirstRows() {
        sut.presentFetchedData(
            ProfileCurrencyFetchData(
                currencies: [
                    .init(code: "USD", title: "US Dollar"),
                    .init(code: "EUR", title: "Euro"),
                    .init(code: "KZT", title: "Kazakhstani Tenge")
                ],
                selectedCurrencyCode: "EUR"
            )
        )

        XCTAssertEqual(sut.viewModel.navigationTitle.text, L10n.profileSelectCurrencyTitle)
        XCTAssertEqual(sut.viewModel.rows.first?.code, "EUR")
        XCTAssertEqual(sut.viewModel.rows.first?.isSelected, true)
    }
}

private final class ProfileCurrencyHandlerSpy: ProfileCurrencyHandler, @unchecked Sendable {
    func handleSelectCurrency(_ currencyCode: String) async {}
    func handleSearchQueryDidChange(_ query: String) async {}
    func handleTapClose() async {}
}
