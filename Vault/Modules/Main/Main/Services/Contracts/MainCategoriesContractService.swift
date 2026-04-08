// Created by Egor Shkarin on 24.03.2026

import Foundation
@preconcurrency import NetworkClient

protocol MainCategoriesContractServicing: Sendable {
    func createCategory(_ request: CategoryCreateRequestDTO) async throws -> CategoryResponseDTO
    func updateCategory(id: String, request: CategoryCreateRequestDTO) async throws -> CategoryResponseDTO
    func listCategories(parameters: CategoriesQueryParameters) async throws -> CategoriesResponseDTO
    func listCategories() async throws -> CategoriesResponseDTO
    func getCategory(id: String, parameters: CategoriesQueryParameters) async throws -> CategoryResponseDTO
    func getCategory(id: String) async throws -> CategoryResponseDTO
    func deleteCategory(id: String) async throws
}

extension MainCategoriesContractServicing {
    func updateCategory(id: String, request: CategoryCreateRequestDTO) async throws -> CategoryResponseDTO {
        try await createCategory(request)
    }

    func listCategories(parameters: CategoriesQueryParameters) async throws -> CategoriesResponseDTO {
        try await listCategories()
    }

    func getCategory(id: String, parameters: CategoriesQueryParameters) async throws -> CategoryResponseDTO {
        try await getCategory(id: id)
    }
}

final class MainCategoriesContractService: MainCategoriesContractServicing {
    private let networkClient: AsyncNetworkClient

    init(networkClient: AsyncNetworkClient) {
        self.networkClient = networkClient
    }

    func createCategory(_ request: CategoryCreateRequestDTO) async throws -> CategoryResponseDTO {
        try await networkClient.request(
            CategoriesAPI.create(request),
            responseType: CategoryResponseDTO.self
        )
    }

    func updateCategory(id: String, request: CategoryCreateRequestDTO) async throws -> CategoryResponseDTO {
        try await networkClient.request(
            CategoriesAPI.update(id: id, request),
            responseType: CategoryResponseDTO.self
        )
    }

    func listCategories() async throws -> CategoriesResponseDTO {
        try await listCategories(parameters: .init())
    }

    func listCategories(parameters: CategoriesQueryParameters) async throws -> CategoriesResponseDTO {
        try await networkClient.request(
            CategoriesAPI.list(parameters),
            responseType: CategoriesResponseDTO.self
        )
    }

    func getCategory(id: String) async throws -> CategoryResponseDTO {
        try await getCategory(id: id, parameters: .init())
    }

    func getCategory(
        id: String,
        parameters: CategoriesQueryParameters
    ) async throws -> CategoryResponseDTO {
        try await networkClient.request(
            CategoriesAPI.get(id: id, parameters: parameters),
            responseType: CategoryResponseDTO.self
        )
    }

    func deleteCategory(id: String) async throws {
        try await networkClient.request(CategoriesAPI.delete(id: id))
    }
}
