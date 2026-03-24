import XCTest
@testable import Vault

final class MainCategoriesContractServiceTests: XCTestCase {
    func testCreateCategoryForwardsBodyAndDecodesResponse() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"category":{"id":"cat-1","name":"Food","icon":"🍔","color":"light_green"}}"#
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
    }
}

extension MainCategoriesContractServiceTests {
    func testListCategoriesForwardsListAndDecodesResponse() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"categories":[{"id":"cat-1","name":"Food","icon":"🍔","color":"light_green"},{"id":"cat-2","name":"Taxi","icon":"🚕","color":"light_blue"}]}"#
        )

        var didCallList = false
        spy.onRequest = { target in
            guard let api = target as? CategoriesAPI,
                  case .list = api else {
                return XCTFail("Expected CategoriesAPI.list")
            }

            didCallList = true
        }

        let sut = MainCategoriesContractService(networkClient: spy)
        let response = try await sut.listCategories()

        XCTAssertTrue(didCallList)
        XCTAssertEqual(response.categories.count, 2)
        XCTAssertEqual(response.categories.first?.id, "cat-1")
        XCTAssertEqual(response.categories.last?.id, "cat-2")
    }
}

extension MainCategoriesContractServiceTests {
    func testGetCategoryForwardsIDAndDecodesResponse() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"category":{"id":"cat-7","name":"Groceries","icon":"🛒","color":"light_orange"}}"#
        )

        var capturedID: String?
        spy.onRequest = { target in
            guard let api = target as? CategoriesAPI,
                  case let .get(id) = api else {
                return XCTFail("Expected CategoriesAPI.get")
            }

            capturedID = id
        }

        let sut = MainCategoriesContractService(networkClient: spy)
        let response = try await sut.getCategory(id: "cat-7")

        XCTAssertEqual(capturedID, "cat-7")
        XCTAssertEqual(response.category.id, "cat-7")
        XCTAssertEqual(response.category.name, "Groceries")
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
