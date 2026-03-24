// Created by Codex on 24.03.2026

import Foundation
@preconcurrency import NetworkClient

protocol MainExpensesContractServicing: Sendable {
    func createExpenses(_ request: ExpensesCreateRequestDTO) async throws -> ExpensesCreateResponseDTO
    func listExpenses(parameters: ExpensesListQueryParameters) async throws -> ExpensesListResponseDTO
    func deleteExpense(id: String) async throws
}

final class MainExpensesContractService: MainExpensesContractServicing {
    private let networkClient: AsyncNetworkClient

    init(networkClient: AsyncNetworkClient) {
        self.networkClient = networkClient
    }

    func createExpenses(_ request: ExpensesCreateRequestDTO) async throws -> ExpensesCreateResponseDTO {
        try await networkClient.request(
            ExpensiesAPI.create(request),
            responseType: ExpensesCreateResponseDTO.self
        )
    }

    func listExpenses(
        parameters: ExpensesListQueryParameters = .init()
    ) async throws -> ExpensesListResponseDTO {
        try await networkClient.request(
            ExpensiesAPI.list(parameters),
            responseType: ExpensesListResponseDTO.self
        )
    }

    func deleteExpense(id: String) async throws {
        try await networkClient.request(ExpensiesAPI.delete(id: id))
    }
}
