// Created by Codex on 24.03.2026

import Foundation
@preconcurrency import NetworkClient

protocol MainSummaryContractServicing: Sendable {
    func getSummary(parameters: SummaryQueryParameters) async throws -> SummaryResponseDTO
    func getSummaryByCategory(
        id: String,
        parameters: SummaryQueryParameters
    ) async throws -> SummaryResponseDTO
}

final class MainSummaryContractService: MainSummaryContractServicing {
    private let networkClient: AsyncNetworkClient

    init(networkClient: AsyncNetworkClient) {
        self.networkClient = networkClient
    }

    func getSummary(
        parameters: SummaryQueryParameters = .init()
    ) async throws -> SummaryResponseDTO {
        try await networkClient.request(
            SummaryAPI.all(parameters),
            responseType: SummaryResponseDTO.self
        )
    }

    func getSummaryByCategory(
        id: String,
        parameters: SummaryQueryParameters = .init()
    ) async throws -> SummaryResponseDTO {
        try await networkClient.request(
            SummaryAPI.byCategory(id: id, parameters: parameters),
            responseType: SummaryResponseDTO.self
        )
    }
}
