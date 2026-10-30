// Created by Egor Shkarin 29.03.2026

import Foundation
@preconcurrency import NetworkClient

// sourcery: AutoMockable
protocol ProfileContractServicing: Sendable {
    func cachedProfile() async -> ProfileResponseDTO?
    func getProfile() async throws -> ProfileResponseDTO
    func refreshProfile() async throws -> ProfileResponseDTO
    func updateProfile(_ request: ProfileUpdateRequestDTO) async throws -> ProfileResponseDTO
    func deleteAccount() async throws
}

extension ProfileContractServicing {
    func refreshProfile() async throws -> ProfileResponseDTO {
        try await getProfile()
    }
}

final class ProfileContractService: ProfileContractServicing, @unchecked Sendable {
    private let networkClient: AsyncNetworkClient
    private let notificationCenter: NotificationCenterServicing
    private let state = State()
    private var logoutObserver: NSObjectProtocol?

    init(
        networkClient: AsyncNetworkClient,
        notificationCenter: NotificationCenterServicing
    ) {
        self.networkClient = networkClient
        self.notificationCenter = notificationCenter

        logoutObserver = notificationCenter.addObserver(
            forName: .authSessionDidLogout
        ) { [weak self] in
            await self?.state.clear()
        }
    }

    deinit {
        if let logoutObserver {
            notificationCenter.removeObserver(logoutObserver)
        }
    }

    func cachedProfile() async -> ProfileResponseDTO? {
        await state.profile
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

    func deleteAccount() async throws {
        try await networkClient.request(AccountAPI.delete)
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
