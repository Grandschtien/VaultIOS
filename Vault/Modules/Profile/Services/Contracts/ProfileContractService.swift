// Created by Egor Shkarin 29.03.2026

import Foundation
@preconcurrency import NetworkClient

protocol ProfileContractServicing: Sendable {
    func getProfile() async throws -> ProfileResponseDTO
    func refreshProfile() async throws -> ProfileResponseDTO
    func updateProfile(_ request: ProfileUpdateRequestDTO) async throws -> ProfileResponseDTO
}

extension ProfileContractServicing {
    func refreshProfile() async throws -> ProfileResponseDTO {
        try await getProfile()
    }
}

final class ProfileContractService: ProfileContractServicing, @unchecked Sendable {
    private let networkClient: AsyncNetworkClient
    private let state = State()
    private var logoutObserver: NSObjectProtocol?

    init(networkClient: AsyncNetworkClient) {
        self.networkClient = networkClient

        logoutObserver = NotificationCenter.default.addObserver(
            forName: .authSessionDidLogout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.state.clear()
            }
        }
    }

    deinit {
        if let logoutObserver {
            NotificationCenter.default.removeObserver(logoutObserver)
        }
    }

    func getProfile() async throws -> ProfileResponseDTO {
        if let cachedProfile = await state.profile {
            return cachedProfile
        }

        return try await refreshProfile()
    }

    func refreshProfile() async throws -> ProfileResponseDTO {
        let profile = try await networkClient.request(
            ProfileAPI.get,
            responseType: ProfileResponseDTO.self
        )

        await state.setProfile(profile)
        return profile
    }

    func updateProfile(_ request: ProfileUpdateRequestDTO) async throws -> ProfileResponseDTO {
        let profile = try await networkClient.request(
            ProfileAPI.update(request),
            responseType: ProfileResponseDTO.self
        )

        await state.setProfile(profile)
        return profile
    }
}

private extension ProfileContractService {
    actor State {
        private(set) var profile: ProfileResponseDTO?

        func setProfile(_ profile: ProfileResponseDTO) {
            self.profile = profile
        }

        func clear() {
            profile = nil
        }
    }
}
