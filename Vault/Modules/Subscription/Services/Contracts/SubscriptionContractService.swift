// Created by Egor Shkarin 08.04.2026

import Foundation
@preconcurrency import NetworkClient

protocol SubscriptionContractServicing: Sendable {
    func approvePurchase(_ request: SubscriptionApproveRequestDTO) async throws
}

final class SubscriptionContractService: SubscriptionContractServicing {
    private let networkClient: AsyncNetworkClient

    init(networkClient: AsyncNetworkClient) {
        self.networkClient = networkClient
    }

    func approvePurchase(_ request: SubscriptionApproveRequestDTO) async throws {
        try await networkClient.request(SubscriptionAPI.approve(request))
    }
}
