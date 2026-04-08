import XCTest
@testable import Vault

final class MainContractsAPITests: XCTestCase {
    func testCategoriesCreateBuildsExpectedConfiguration() {
        let target = CategoriesAPI.create(
            .init(name: "Food", icon: "🍔", color: "light_green")
        )

        XCTAssertEqual(target.path, "/categories")
        XCTAssertEqual(target.method.rawValue, "POST")
        XCTAssertEqual(target.host, "localhost")
        XCTAssertEqual(target.timeoutInterval, 30)
        XCTAssertEqual(target.url.absoluteString, "https://localhost:8080/categories")

        guard case .custonJSON = target.requestType else {
            return XCTFail("Expected custom JSON request type")
        }
    }
}

extension MainContractsAPITests {
    func testCategoriesListWithRangeBuildsExpectedQuery() {
        let from = Date(timeIntervalSince1970: 1_772_265_600)
        let to = Date(timeIntervalSince1970: 1_774_943_999)
        let target = CategoriesAPI.list(
            .init(
                from: from,
                to: to
            )
        )

        XCTAssertEqual(target.path, "/categories")
        XCTAssertEqual(target.method.rawValue, "GET")

        guard case let .query(query, _) = target.requestType else {
            return XCTFail("Expected query request type")
        }

        XCTAssertEqual(query["from"] as? String, "2026-03-01T00:00:00Z")
        XCTAssertEqual(query["to"] as? String, "2026-03-31T23:59:59Z")
    }
}

extension MainContractsAPITests {
    func testCategoriesGetAndDeleteBuildExpectedPaths() {
        let getTarget = CategoriesAPI.get(id: "cat-1", parameters: .init())
        let deleteTarget = CategoriesAPI.delete(id: "cat-1")

        XCTAssertEqual(getTarget.path, "/categories/cat-1")
        XCTAssertEqual(getTarget.method.rawValue, "GET")
        XCTAssertEqual(deleteTarget.path, "/categories/cat-1")
        XCTAssertEqual(deleteTarget.method.rawValue, "DELETE")

        guard case .plain = getTarget.requestType,
              case .plain = deleteTarget.requestType
        else {
            return XCTFail("Expected plain request type")
        }
    }
}

extension MainContractsAPITests {
    func testCategoriesGetWithRangeBuildsExpectedQuery() {
        let from = Date(timeIntervalSince1970: 1_772_265_600)
        let to = Date(timeIntervalSince1970: 1_774_943_999)
        let target = CategoriesAPI.get(
            id: "cat-1",
            parameters: .init(
                from: from,
                to: to
            )
        )

        XCTAssertEqual(target.path, "/categories/cat-1")
        XCTAssertEqual(target.method.rawValue, "GET")

        guard case let .query(query, _) = target.requestType else {
            return XCTFail("Expected query request type")
        }

        XCTAssertEqual(query["from"] as? String, "2026-03-01T00:00:00Z")
        XCTAssertEqual(query["to"] as? String, "2026-03-31T23:59:59Z")
    }
}

extension MainContractsAPITests {
    func testExpensiesListWithAllParametersBuildsQuery() {
        let from = Date(timeIntervalSince1970: 1_735_689_600)
        let to = Date(timeIntervalSince1970: 1_736_553_000)

        let target = ExpensiesAPI.list(
            .init(
                category: "cat-1",
                from: from,
                to: to,
                cursor: "cursor-token",
                limit: 25
            )
        )

        XCTAssertEqual(target.path, "/expenses")
        XCTAssertEqual(target.method.rawValue, "GET")

        guard case let .query(query, _) = target.requestType else {
            return XCTFail("Expected query request type")
        }

        XCTAssertEqual(query["category"] as? String, "cat-1")
        XCTAssertEqual(query["cursor"] as? String, "cursor-token")
        XCTAssertEqual(limitValue(in: query), 25)
        XCTAssertEqual(query["from"] as? String, "2025-01-01T00:00:00Z")
        XCTAssertEqual(query["to"] as? String, "2025-01-11T23:50:00Z")
    }
}

extension MainContractsAPITests {
    func testExpensiesListWithoutParametersUsesPlainRequest() {
        let target = ExpensiesAPI.list(.init())

        guard case .plain = target.requestType else {
            return XCTFail("Expected plain request type when no query params are set")
        }
    }
}

extension MainContractsAPITests {
    func testSummaryAllAndByCategoryBuildExpectedConfiguration() {
        let allTarget = SummaryAPI.all(.init())
        let from = Date(timeIntervalSince1970: 1_735_689_600)
        let to = Date(timeIntervalSince1970: 1_736_553_000)
        let byCategoryTarget = SummaryAPI.byCategory(
            id: "cat-1",
            parameters: .init(from: from, to: to)
        )

        XCTAssertEqual(allTarget.path, "/expenses/summary")
        XCTAssertEqual(allTarget.method.rawValue, "GET")
        XCTAssertEqual(byCategoryTarget.path, "/expenses/summary/cat-1")

        guard case .plain = allTarget.requestType else {
            return XCTFail("Expected plain request type without query")
        }

        guard case let .query(query, _) = byCategoryTarget.requestType else {
            return XCTFail("Expected query request type")
        }

        XCTAssertEqual(query["from"] as? String, "2025-01-01T00:00:00Z")
        XCTAssertEqual(query["to"] as? String, "2025-01-11T23:50:00Z")
    }
}

extension MainContractsAPITests {
    func testAIParseBuildsExpectedConfiguration() {
        let target = AIParseAPI.parse(
            .init(
                text: "Coffee 5",
                currencyHint: "USD"
            )
        )

        XCTAssertEqual(target.path, "/ai/parse")
        XCTAssertEqual(target.method.rawValue, "POST")
        XCTAssertEqual(target.host, "localhost")
        XCTAssertEqual(target.timeoutInterval, 30)
        XCTAssertEqual(target.url.absoluteString, "https://localhost:8080/ai/parse")

        guard case .custonJSON = target.requestType else {
            return XCTFail("Expected custom JSON request type")
        }
    }
}

extension MainContractsAPITests {
    func testCurrencyRateBuildExpectedConfiguration() {
        let target = CurrencyRateAPI.get(currency: "USD")

        XCTAssertEqual(target.path, "/currency-rate")
        XCTAssertEqual(target.method.rawValue, "GET")

        guard case let .query(query, _) = target.requestType else {
            return XCTFail("Expected query request type")
        }

        XCTAssertEqual(query["currency"] as? String, "USD")
    }
}

private extension MainContractsAPITests {
    func limitValue(in query: [String: Any]) -> Int? {
        if let value = query["limit"] as? Int {
            return value
        }

        if let value = query["limit"] as? NSNumber {
            return value.intValue
        }

        return nil
    }
}
