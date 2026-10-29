import XCTest
@testable import Vylok

final class ProfileCurrencyInteractorTests: XCTestCase {
    private var presenter: ProfileCurrencyPresentationLogicMock!
    private var router: ProfileCurrencyRoutingLogicMock!
    private var currencyProvider: RegistrationCurrencyProvidingMock!
    private var output: ProfileCurrencySelectionOutputMock!

    override func setUp() {
        super.setUp()
        presenter = ProfileCurrencyPresentationLogicMock()
        router = ProfileCurrencyRoutingLogicMock()
        currencyProvider = RegistrationCurrencyProvidingMock()
        currencyProvider.fiatCurrenciesReturnValue = [
            .init(code: "USD", title: "US Dollar"),
            .init(code: "EUR", title: "Euro"),
            .init(code: "KZT", title: "Kazakhstani Tenge")
        ]
        output = ProfileCurrencySelectionOutputMock()
    }

    override func tearDown() {
        output = nil
        currencyProvider = nil
        router = nil
        presenter = nil
        super.tearDown()
    }
}

extension ProfileCurrencyInteractorTests {
    func testFetchDataBuildsRowsWithCurrentCurrencySelected() async {
        let sut = ProfileCurrencyInteractor(
            presenter: presenter,
            router: router,
            currencyProvider: currencyProvider,
            output: output,
            currentCurrencyCode: "EUR"
        )

        await sut.fetchData()

        guard let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter updates")
        }

        XCTAssertEqual(last.selectedCurrencyCode, "EUR")
        XCTAssertEqual(last.currencies.count, 3)
    }
}

extension ProfileCurrencyInteractorTests {
    func testHandleTapCloseClosesPicker() async {
        let sut = ProfileCurrencyInteractor(
            presenter: presenter,
            router: router,
            currencyProvider: currencyProvider,
            output: output,
            currentCurrencyCode: "EUR"
        )

        await sut.handleTapClose()

        XCTAssertEqual(router.closeCallsCount, 1)
    }
}

extension ProfileCurrencyInteractorTests {
    func testHandleSearchQueryDidChangeFiltersCurrencies() async {
        let sut = ProfileCurrencyInteractor(
            presenter: presenter,
            router: router,
            currencyProvider: currencyProvider,
            output: output,
            currentCurrencyCode: "EUR"
        )

        await sut.fetchData()
        await sut.handleSearchQueryDidChange("kaz")

        guard let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter updates")
        }

        XCTAssertEqual(last.currencies.map(\.code), ["KZT"])
    }
}

extension ProfileCurrencyInteractorTests {
    func testHandleSelectCurrencyNotifiesOutputAndClosesPicker() async {
        let sut = ProfileCurrencyInteractor(
            presenter: presenter,
            router: router,
            currencyProvider: currencyProvider,
            output: output,
            currentCurrencyCode: "EUR"
        )

        await sut.fetchData()
        await sut.handleSelectCurrency("USD")

        XCTAssertEqual(router.closeCallsCount, 1)
        XCTAssertEqual(output.handleDidSelectCurrencyReceivedInvocations, ["USD"])
    }
}
