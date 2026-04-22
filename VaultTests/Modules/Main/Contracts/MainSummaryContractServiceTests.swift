import XCTest
@testable import Vault

final class MainSummaryContractServiceTests: XCTestCase {
    func testGetSummaryForwardsRangeAndDecodesByCategory() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"total":456.78,"total_usd":456.78,"currency":"USD","by_category":[{"category":"cat-1","total":300},{"category":"cat-2","total":156.78}]}"#
        )

        let from = Date(timeIntervalSince1970: 1_735_689_600)
        let to = Date(timeIntervalSince1970: 1_736_553_000)
        let parameters = SummaryQueryParameters(from: from, to: to)

        var capturedParameters: SummaryQueryParameters?
        spy.onRequest = { target in
            guard let api = target as? SummaryAPI,
                  case let .all(requestParameters) = api else {
                return XCTFail("Expected SummaryAPI.all")
            }

            capturedParameters = requestParameters
        }

        let sut = MainSummaryContractService(networkClient: spy)
        let response = try await sut.getSummary(parameters: parameters)

        XCTAssertEqual(capturedParameters, parameters)
        XCTAssertEqual(response.total, 456.78)
        XCTAssertEqual(response.totalUsd, 456.78)
        XCTAssertEqual(response.currency, "USD")
        XCTAssertNil(response.category)
        XCTAssertEqual(response.byCategory?.count, 2)
    }
}

extension MainSummaryContractServiceTests {
    func testGetSummaryDecodesEmptyByCategoryArray() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"total":0,"total_usd":0,"currency":"USD","by_category":[]}"#
        )

        let sut = MainSummaryContractService(networkClient: spy)
        let response = try await sut.getSummary(parameters: .init())

        XCTAssertEqual(response.total, 0)
        XCTAssertEqual(response.totalUsd, 0)
        XCTAssertEqual(response.currency, "USD")
        XCTAssertEqual(response.byCategory, [])
    }
}

extension MainSummaryContractServiceTests {
    func testGetSummaryByCategoryForwardsIDAndRangeAndDecodesCategorySummary() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"category":"cat-1","total":53210,"total_usd":123.45,"currency":"KZT"}"#
        )

        let from = Date(timeIntervalSince1970: 1_735_689_600)
        let to = Date(timeIntervalSince1970: 1_736_553_000)
        let parameters = SummaryQueryParameters(from: from, to: to)

        var capturedID: String?
        var capturedParameters: SummaryQueryParameters?
        spy.onRequest = { target in
            guard let api = target as? SummaryAPI,
                  case let .byCategory(id, requestParameters) = api else {
                return XCTFail("Expected SummaryAPI.byCategory")
            }

            capturedID = id
            capturedParameters = requestParameters
        }

        let sut = MainSummaryContractService(networkClient: spy)
        let response = try await sut.getSummaryByCategory(id: "cat-1", parameters: parameters)

        XCTAssertEqual(capturedID, "cat-1")
        XCTAssertEqual(capturedParameters, parameters)
        XCTAssertEqual(response.category, "cat-1")
        XCTAssertEqual(response.total, 53210)
        XCTAssertEqual(response.totalUsd, 123.45)
        XCTAssertEqual(response.currency, "KZT")
        XCTAssertNil(response.byCategory)
    }
}
