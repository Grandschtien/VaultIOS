import XCTest
@testable import Vault

final class MainAIParseContractServiceTests: XCTestCase {
    func testParseForwardsPayloadAndDecodesSingleExpense() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"expenses":[{"title":"Coffee","amount":5,"currency":"USD","category":"Food","suggested_category":null,"confidence":0.92}],"usage":{"entries_used":1,"entries_limit":10,"resets_at":"2025-01-01T10:00:00Z"}}"#
        )

        var capturedRequest: AIParseRequestDTO?
        spy.onRequest = { target in
            guard let api = target as? AIParseAPI,
                  case let .parse(request) = api else {
                return XCTFail("Expected AIParseAPI.parse")
            }

            capturedRequest = request
        }

        let sut = MainAIParseContractService(networkClient: spy)
        let response = try await sut.parse(
            .init(
                text: "Coffee 5",
                currencyHint: "USD"
            )
        )

        XCTAssertEqual(capturedRequest?.text, "Coffee 5")
        XCTAssertEqual(capturedRequest?.currencyHint, "USD")
        XCTAssertEqual(response.expenses.count, 1)
        XCTAssertEqual(response.expenses.first?.title, "Coffee")
        XCTAssertEqual(response.expenses.first?.suggestedCategory, nil)
        XCTAssertEqual(response.usage.entriesUsed, 1)
    }
}

extension MainAIParseContractServiceTests {
    func testParseDecodesMultipleExpensesAndNoExpenseError() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"expenses":[{"title":"Coffee","amount":5,"currency":"USD","category":"Food","suggested_category":null,"confidence":0.92},{"title":"Taxi","amount":12,"currency":"EUR","category":"UNMAPPED","suggested_category":"Transport","confidence":0.81}],"usage":{"entries_used":2,"entries_limit":10,"resets_at":"2025-01-01T10:00:00Z"}}"#
        )

        let sut = MainAIParseContractService(networkClient: spy)
        let response = try await sut.parse(
            .init(
                text: "Coffee and taxi",
                currencyHint: "USD"
            )
        )

        XCTAssertEqual(response.expenses.count, 2)
        XCTAssertEqual(response.expenses.last?.suggestedCategory, "Transport")

        spy.setResponse(
            json: #"{"expenses":[],"usage":{"entries_used":2,"entries_limit":10,"resets_at":"2025-01-01T10:00:00Z"},"error":"NO_EXPENSE_DETECTED"}"#
        )

        let noExpenseResponse = try await sut.parse(
            .init(
                text: "Hello",
                currencyHint: "USD"
            )
        )

        XCTAssertEqual(noExpenseResponse.error, "NO_EXPENSE_DETECTED")
        XCTAssertTrue(noExpenseResponse.expenses.isEmpty)
    }
}
