import Foundation
@preconcurrency import NetworkClient

protocol MainAIParseContractServicing: Sendable {
    func parse(_ request: AIParseRequestDTO) async throws -> AIParseResponseDTO
}

final class MainAIParseContractService: MainAIParseContractServicing {
    private let networkClient: AsyncNetworkClient

    init(networkClient: AsyncNetworkClient) {
        self.networkClient = networkClient
    }

    func parse(_ request: AIParseRequestDTO) async throws -> AIParseResponseDTO {
        try await networkClient.request(
            AIParseAPI.parse(request),
            responseType: AIParseResponseDTO.self
        )
    }
}
