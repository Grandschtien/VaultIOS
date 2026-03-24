// Created by Codex on 24.03.2026

import Foundation
@preconcurrency import NetworkClient

protocol MainCategoriesContractServicing: Sendable {
    func createCategory(_ request: CategoryCreateRequestDTO) async throws -> CategoryResponseDTO
    func listCategories() async throws -> CategoriesResponseDTO
    func getCategory(id: String) async throws -> CategoryResponseDTO
    func deleteCategory(id: String) async throws
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

    func listCategories() async throws -> CategoriesResponseDTO {
        try await networkClient.request(
            CategoriesAPI.list,
            responseType: CategoriesResponseDTO.self
        )
    }

    func getCategory(id: String) async throws -> CategoryResponseDTO {
        try await networkClient.request(
            CategoriesAPI.get(id: id),
            responseType: CategoryResponseDTO.self
        )
    }

    func deleteCategory(id: String) async throws {
        try await networkClient.request(CategoriesAPI.delete(id: id))
    }
}
