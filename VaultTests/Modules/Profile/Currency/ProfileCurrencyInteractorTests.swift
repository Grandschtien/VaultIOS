import XCTest
@testable import Vault

@MainActor
final class ProfileCurrencyInteractorTests: XCTestCase {
    func testFetchDataBuildsRowsWithCurrentCurrencySelected() async {
        let presenter = ProfileCurrencyPresenterSpy()
        let router = ProfileCurrencyRouterSpy()
        let output = ProfileCurrencySelectionOutputSpy()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            currentCurrencyCode: "EUR"
        )

        await sut.fetchData()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter updates")
        }

        XCTAssertEqual(last.selectedCurrencyCode, "EUR")
        XCTAssertEqual(last.currencies.count, 3)
    }
}

extension ProfileCurrencyInteractorTests {
    func testHandleTapCloseClosesPicker() async {
        let presenter = ProfileCurrencyPresenterSpy()
        let router = ProfileCurrencyRouterSpy()
        let output = ProfileCurrencySelectionOutputSpy()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            currentCurrencyCode: "EUR"
        )

        await sut.handleTapClose()

        XCTAssertEqual(router.closeCallsCount, 1)
    }
}

extension ProfileCurrencyInteractorTests {
    func testHandleSearchQueryDidChangeFiltersCurrencies() async {
        let presenter = ProfileCurrencyPresenterSpy()
        let router = ProfileCurrencyRouterSpy()
        let output = ProfileCurrencySelectionOutputSpy()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            currentCurrencyCode: "EUR"
        )

        await sut.fetchData()
        await sut.handleSearchQueryDidChange("kaz")

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter updates")
        }

        XCTAssertEqual(last.currencies.map(\.code), ["KZT"])
    }
}

extension ProfileCurrencyInteractorTests {
    func testHandleSelectCurrencyNotifiesOutputAndClosesPicker() async {
        let presenter = ProfileCurrencyPresenterSpy()
        let router = ProfileCurrencyRouterSpy()
        let output = ProfileCurrencySelectionOutputSpy()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            currentCurrencyCode: "EUR"
        )

        await sut.fetchData()
        await sut.handleSelectCurrency("USD")

        XCTAssertEqual(router.closeCallsCount, 1)
        XCTAssertEqual(output.lastSelectedCurrencyCode, "USD")
    }
}

private extension ProfileCurrencyInteractorTests {
    func makeSut(
        presenter: ProfileCurrencyPresentationLogic,
        router: ProfileCurrencyRoutingLogic,
        output: ProfileCurrencySelectionOutput,
        currentCurrencyCode: String
    ) -> ProfileCurrencyInteractor {
        ProfileCurrencyInteractor(
            presenter: presenter,
            router: router,
            currencyProvider: CurrencyProviderStub(),
            output: output,
            currentCurrencyCode: currentCurrencyCode
        )
    }
}

@MainActor
private final class ProfileCurrencyPresenterSpy: ProfileCurrencyPresentationLogic {
    private(set) var presentedData: [ProfileCurrencyFetchData] = []

    func presentFetchedData(_ data: ProfileCurrencyFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class ProfileCurrencyRouterSpy: ProfileCurrencyRoutingLogic {
    private(set) var closeCallsCount = 0

    func close() {
        closeCallsCount += 1
    }
}

private final class ProfileCurrencySelectionOutputSpy: ProfileCurrencySelectionOutput, @unchecked Sendable {
    private(set) var lastSelectedCurrencyCode: String?

    func handleDidSelectCurrency(_ currencyCode: String) async {
        lastSelectedCurrencyCode = currencyCode
    }
}

private struct CurrencyProviderStub: RegistrationCurrencyProviding {
    func fiatCurrencies() -> [RegistrationCurrency] {
        [
            .init(code: "USD", title: "US Dollar"),
            .init(code: "EUR", title: "Euro"),
            .init(code: "KZT", title: "Kazakhstani Tenge")
        ]
    }
}
