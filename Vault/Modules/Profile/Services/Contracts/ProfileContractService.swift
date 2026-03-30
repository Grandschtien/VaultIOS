// Created by Egor Shkarin 29.03.2026

import Foundation
@preconcurrency import NetworkClient

protocol ProfileContractServicing: Sendable {
    func getProfile() async throws -> ProfileResponseDTO
    func updateProfile(_ request: ProfileUpdateRequestDTO) async throws -> ProfileResponseDTO
}

final class ProfileContractService: ProfileContractServicing {
    private let networkClient: AsyncNetworkClient

    init(networkClient: AsyncNetworkClient) {
        self.networkClient = networkClient
    }

    func getProfile() async throws -> ProfileResponseDTO {
        try await networkClient.request(
            ProfileAPI.get,
            responseType: ProfileResponseDTO.self
        )
    }

    func updateProfile(_ request: ProfileUpdateRequestDTO) async throws -> ProfileResponseDTO {
        try await networkClient.request(
            ProfileAPI.update(request),
            responseType: ProfileResponseDTO.self
        )
    }
}
