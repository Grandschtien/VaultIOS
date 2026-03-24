import XCTest
@testable import Vault

final class MainExpensesContractServiceTests: XCTestCase {
    func testCreateExpensesForwardsPayloadAndDecodesResponse() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"expenses":[{"id":"exp-1","title":"iPhone","description":"Apple Store","amount":650.42,"currency":"USD","category":"cat-1","time_of_add":"2025-01-01T10:00:00Z"}]}"#
        )

        var capturedRequest: ExpensesCreateRequestDTO?
        spy.onRequest = { target in
            guard let api = target as? ExpensiesAPI,
                  case let .create(request) = api else {
                return XCTFail("Expected ExpensiesAPI.create")
            }

            capturedRequest = request
        }

        let sut = MainExpensesContractService(networkClient: spy)
        let timeOfAdd = Date(timeIntervalSince1970: 1_735_725_600)
        let response = try await sut.createExpenses(
            .init(
                expenses: [
                    .init(
                        title: "iPhone",
                        description: "Apple Store",
                        amount: 600,
                        currency: "EUR",
                        category: "cat-1",
                        timeOfAdd: timeOfAdd
                    )
                ]
            )
        )

        XCTAssertEqual(capturedRequest?.expenses.count, 1)
        XCTAssertEqual(capturedRequest?.expenses.first?.title, "iPhone")
        XCTAssertEqual(capturedRequest?.expenses.first?.description, "Apple Store")
        XCTAssertEqual(capturedRequest?.expenses.first?.amount, 600)
        XCTAssertEqual(capturedRequest?.expenses.first?.currency, "EUR")
        XCTAssertEqual(capturedRequest?.expenses.first?.category, "cat-1")
        XCTAssertEqual(capturedRequest?.expenses.first?.timeOfAdd, timeOfAdd)

        XCTAssertEqual(response.expenses.count, 1)
        XCTAssertEqual(response.expenses.first?.id, "exp-1")
        XCTAssertEqual(response.expenses.first?.description, "Apple Store")
    }
}

extension MainExpensesContractServiceTests {
    func testListExpensesForwardsAllFiltersAndDecodesCursor() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"expenses":[{"id":"exp-1","title":"Coffee","description":null,"amount":5.5,"currency":"USD","category":"cat-1","time_of_add":"2025-01-02T08:30:00Z"}],"next_cursor":"next-1","has_more":true}"#
        )

        let from = Date(timeIntervalSince1970: 1_735_689_600)
        let to = Date(timeIntervalSince1970: 1_736_553_000)
        let params = ExpensesListQueryParameters(
            category: "cat-1",
            from: from,
            to: to,
            cursor: "cursor-1",
            limit: 50
        )

        var capturedParameters: ExpensesListQueryParameters?
        spy.onRequest = { target in
            guard let api = target as? ExpensiesAPI,
                  case let .list(parameters) = api else {
                return XCTFail("Expected ExpensiesAPI.list")
            }

            capturedParameters = parameters
        }

        let sut = MainExpensesContractService(networkClient: spy)
        let response = try await sut.listExpenses(parameters: params)

        XCTAssertEqual(capturedParameters, params)
        XCTAssertEqual(response.expenses.count, 1)
        XCTAssertEqual(response.expenses.first?.title, "Coffee")
        XCTAssertNil(response.expenses.first?.description)
        XCTAssertEqual(response.nextCursor, "next-1")
        XCTAssertTrue(response.hasMore)
    }
}

extension MainExpensesContractServiceTests {
    func testListExpensesDecodesMissingNextCursorAsNil() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"expenses":[{"id":"exp-2","title":"Taxi","amount":12.2,"currency":"USD","category":"cat-2","time_of_add":"2025-01-03T12:00:00Z"}],"has_more":false}"#
        )

        let sut = MainExpensesContractService(networkClient: spy)
        let response = try await sut.listExpenses(parameters: .init())

        XCTAssertEqual(response.expenses.count, 1)
        XCTAssertEqual(response.expenses.first?.id, "exp-2")
        XCTAssertNil(response.nextCursor)
        XCTAssertFalse(response.hasMore)
    }
}

extension MainExpensesContractServiceTests {
    func testDeleteExpenseForwardsID() async throws {
        let spy = AsyncNetworkClientContractSpy()

        var capturedID: String?
        spy.onRequestWithoutResponse = { target in
            guard let api = target as? ExpensiesAPI,
                  case let .delete(id) = api else {
                return XCTFail("Expected ExpensiesAPI.delete")
            }

            capturedID = id
        }

        let sut = MainExpensesContractService(networkClient: spy)
        try await sut.deleteExpense(id: "exp-9")

        XCTAssertEqual(capturedID, "exp-9")
    }
}
