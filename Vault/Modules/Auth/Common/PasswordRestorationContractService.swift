import Foundation
@preconcurrency import NetworkClient

protocol PasswordRestorationContractServicing: Sendable {
    func requestPasswordReset(_ request: ForgotPasswordRequestDTO) async throws
    func resetPassword(_ request: ResetPasswordRequestDTO) async throws
}

final class PasswordRestorationContractService: PasswordRestorationContractServicing {
    private let networkClient: AsyncNetworkClient

    init(networkClient: AsyncNetworkClient) {
        self.networkClient = networkClient
    }

    func requestPasswordReset(_ request: ForgotPasswordRequestDTO) async throws {
        try await networkClient.request(AuthAPI.forgotPassword(request))
    }

    func resetPassword(_ request: ResetPasswordRequestDTO) async throws {
        try await networkClient.request(AuthAPI.resetPassword(request))
    }
}
