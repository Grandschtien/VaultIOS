import XCTest
@testable import Vault

final class MainCategoriesContractServiceTests: XCTestCase {
    func testCreateCategoryForwardsBodyAndDecodesResponse() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"category":{"id":"cat-1","name":"Food","icon":"🍔","color":"light_green","total_spent_usd":95.1,"total_spent":110.5,"currency":"EUR"}}"#
        )

        var capturedDTO: CategoryCreateRequestDTO?
        spy.onRequest = { target in
            guard let api = target as? CategoriesAPI,
                  case let .create(dto) = api else {
                return XCTFail("Expected CategoriesAPI.create")
            }

            capturedDTO = dto
        }

        let sut = MainCategoriesContractService(networkClient: spy)
        let response = try await sut.createCategory(
            .init(name: "Food", icon: "🍔", color: "light_green")
        )

        XCTAssertEqual(capturedDTO?.name, "Food")
        XCTAssertEqual(capturedDTO?.icon, "🍔")
        XCTAssertEqual(capturedDTO?.color, "light_green")

        XCTAssertEqual(response.category.id, "cat-1")
        XCTAssertEqual(response.category.name, "Food")
        XCTAssertEqual(response.category.icon, "🍔")
        XCTAssertEqual(response.category.color, "light_green")
        XCTAssertEqual(response.category.totalSpentUsd, 95.1)
        XCTAssertEqual(response.category.totalSpent, 110.5)
        XCTAssertEqual(response.category.currency, "EUR")
    }
}

extension MainCategoriesContractServiceTests {
    func testListCategoriesForwardsRangeAndDecodesResponse() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"categories":[{"id":"cat-1","name":"Food","icon":"🍔","color":"light_green","total_spent_usd":8,"total_spent":10,"currency":"USD"},{"id":"cat-2","name":"Taxi","icon":"🚕","color":"light_blue","total_spent_usd":15.3,"total_spent":20.2,"currency":"KZT"}]}"#
        )

        let parameters = CategoriesQueryParameters(
            from: Date(timeIntervalSince1970: 1_772_265_600),
            to: Date(timeIntervalSince1970: 1_774_943_999)
        )
        var capturedParameters: CategoriesQueryParameters?
        spy.onRequest = { target in
            guard let api = target as? CategoriesAPI,
                  case let .list(requestParameters) = api else {
                return XCTFail("Expected CategoriesAPI.list")
            }

            capturedParameters = requestParameters
        }

        let sut = MainCategoriesContractService(networkClient: spy)
        let response = try await sut.listCategories(parameters: parameters)

        XCTAssertEqual(capturedParameters, parameters)
        XCTAssertEqual(response.categories.count, 2)
        XCTAssertEqual(response.categories.first?.id, "cat-1")
        XCTAssertEqual(response.categories.last?.id, "cat-2")
        XCTAssertEqual(response.categories.first?.totalSpentUsd, 8)
        XCTAssertEqual(response.categories.first?.totalSpent, 10)
        XCTAssertEqual(response.categories.first?.currency, "USD")
        XCTAssertEqual(response.categories.last?.totalSpentUsd, 15.3)
        XCTAssertEqual(response.categories.last?.totalSpent, 20.2)
        XCTAssertEqual(response.categories.last?.currency, "KZT")
    }
}

extension MainCategoriesContractServiceTests {
    func testGetCategoryForwardsIDAndRangeAndDecodesResponse() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"category":{"id":"cat-7","name":"Groceries","icon":"🛒","color":"light_orange","total_spent_usd":40,"total_spent":45,"currency":"USD"}}"#
        )

        var capturedID: String?
        let parameters = CategoriesQueryParameters(
            from: Date(timeIntervalSince1970: 1_772_265_600),
            to: Date(timeIntervalSince1970: 1_774_943_999)
        )
        var capturedParameters: CategoriesQueryParameters?
        spy.onRequest = { target in
            guard let api = target as? CategoriesAPI,
                  case let .get(id, requestParameters) = api else {
                return XCTFail("Expected CategoriesAPI.get")
            }

            capturedID = id
            capturedParameters = requestParameters
        }

        let sut = MainCategoriesContractService(networkClient: spy)
        let response = try await sut.getCategory(
            id: "cat-7",
            parameters: parameters
        )

        XCTAssertEqual(capturedID, "cat-7")
        XCTAssertEqual(capturedParameters, parameters)
        XCTAssertEqual(response.category.id, "cat-7")
        XCTAssertEqual(response.category.name, "Groceries")
        XCTAssertEqual(response.category.totalSpentUsd, 40)
        XCTAssertEqual(response.category.totalSpent, 45)
        XCTAssertEqual(response.category.currency, "USD")
    }
}

extension MainCategoriesContractServiceTests {
    func testUpdateCategoryForwardsBodyAndDecodesResponse() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: ##"{"category":{"id":"cat-9","name":"Travel","icon":"✈️","color":"#A0E7E5","total_spent_usd":14,"total_spent":18,"currency":"KZT"}}"##
        )

        var capturedID: String?
        var capturedDTO: CategoryCreateRequestDTO?
        spy.onRequest = { target in
            guard let api = target as? CategoriesAPI,
                  case let .update(id, dto) = api else {
                return XCTFail("Expected CategoriesAPI.update")
            }

            capturedID = id
            capturedDTO = dto
        }

        let sut = MainCategoriesContractService(networkClient: spy)
        let response = try await sut.updateCategory(
            id: "cat-9",
            request: .init(name: "Travel", icon: "✈️", color: "#A0E7E5")
        )

        XCTAssertEqual(capturedID, "cat-9")
        XCTAssertEqual(capturedDTO?.name, "Travel")
        XCTAssertEqual(capturedDTO?.icon, "✈️")
        XCTAssertEqual(capturedDTO?.color, "#A0E7E5")
        XCTAssertEqual(response.category.id, "cat-9")
        XCTAssertEqual(response.category.color, "#A0E7E5")
        XCTAssertEqual(response.category.totalSpentUsd, 14)
        XCTAssertEqual(response.category.totalSpent, 18)
        XCTAssertEqual(response.category.currency, "KZT")
    }
}

extension MainCategoriesContractServiceTests {
    func testDeleteCategoryForwardsID() async throws {
        let spy = AsyncNetworkClientContractSpy()

        var capturedID: String?
        spy.onRequestWithoutResponse = { target in
            guard let api = target as? CategoriesAPI,
                  case let .delete(id) = api else {
                return XCTFail("Expected CategoriesAPI.delete")
            }

            capturedID = id
        }

        let sut = MainCategoriesContractService(networkClient: spy)
        try await sut.deleteCategory(id: "cat-3")

        XCTAssertEqual(capturedID, "cat-3")
    }
}
