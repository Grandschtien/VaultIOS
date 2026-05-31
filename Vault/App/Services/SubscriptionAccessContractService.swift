// Created by Egor Shkarin 31.05.2026

import Foundation
@preconcurrency import NetworkClient

protocol SubscriptionAccessContractServicing: Sendable {
    func getSubscription() async throws -> SubscriptionAccessSnapshot
    func refreshSubscription() async throws -> SubscriptionAccessSnapshot
}

extension SubscriptionAccessContractServicing {
    func refreshSubscription() async throws -> SubscriptionAccessSnapshot {
        try await getSubscription()
    }
}

final class SubscriptionAccessContractService: SubscriptionAccessContractServicing, @unchecked Sendable {
    private let networkClient: AsyncNetworkClient

    init(networkClient: AsyncNetworkClient) {
        self.networkClient = networkClient
    }

    func getSubscription() async throws -> SubscriptionAccessSnapshot {
        try await refreshSubscription()
    }

    func refreshSubscription() async throws -> SubscriptionAccessSnapshot {
        let response = try await networkClient.request(
            SubscriptionAccessAPI.get,
            responseType: SubscriptionAccessResponseDTO.self
        )

        return SubscriptionAccessSnapshot(response: response)
    }
}
