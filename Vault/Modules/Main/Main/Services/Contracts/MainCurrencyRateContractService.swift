// Created by Codex on 25.03.2026

import Foundation
@preconcurrency import NetworkClient

protocol MainCurrencyRateContractServicing: Sendable {
    func getCurrencyRate(currency: String) async throws -> CurrencyRateResponseDTO
}

final class MainCurrencyRateContractService: MainCurrencyRateContractServicing {
    private let networkClient: AsyncNetworkClient

    init(networkClient: AsyncNetworkClient) {
        self.networkClient = networkClient
    }

    func getCurrencyRate(currency: String) async throws -> CurrencyRateResponseDTO {
        try await networkClient.request(
            CurrencyRateAPI.get(currency: currency),
            responseType: CurrencyRateResponseDTO.self
        )
    }
}
