import XCTest
@testable import Vault

final class MainCurrencyRateContractServiceTests: XCTestCase {
    func testGetCurrencyRateForwardsCurrencyAndDecodesResponse() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"currency":"USD","rate":1.23}"#
        )

        var capturedCurrency: String?
        spy.onRequest = { target in
            guard let api = target as? CurrencyRateAPI,
                  case let .get(currency) = api else {
                return XCTFail("Expected CurrencyRateAPI.get")
            }

            capturedCurrency = currency
        }

        let sut = MainCurrencyRateContractService(networkClient: spy)
        let response = try await sut.getCurrencyRate(currency: "USD")

        XCTAssertEqual(capturedCurrency, "USD")
        XCTAssertEqual(response.currency, "USD")
        XCTAssertEqual(response.rate, 1.23)
    }
}
