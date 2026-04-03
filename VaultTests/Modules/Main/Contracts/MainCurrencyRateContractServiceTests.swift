import XCTest
@testable import Vault

final class MainCurrencyRateContractServiceTests: XCTestCase {
    func testGetCurrencyRateForwardsCurrencyAndDecodesResponse() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"currency":"USD","rateToUsd":1.23,"asOf":"2026-01-01"}"#
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
        XCTAssertEqual(response.rateToUsd, 1.23)
        XCTAssertEqual(response.asOf, "2026-01-01")
    }
}
