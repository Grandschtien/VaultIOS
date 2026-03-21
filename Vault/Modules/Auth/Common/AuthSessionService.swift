//
//  AuthSessionService.swift
//  Vault
//
//  Created by Egor Shkarin on 21.03.2026.
//

import Foundation
@preconcurrency import NetworkClient

extension Notification.Name {
    static let authSessionDidLogout = Notification.Name("authSessionDidLogout")
}

protocol AuthSessionServiceProtocol: Sendable {
    func hasValidSession() async -> Bool
    func refreshAccessToken() async throws -> AuthTokenDTO
    func accessToken() async -> String?
    func logout() async
}

actor AuthSessionService: AuthSessionServiceProtocol {
    enum Error: Swift.Error {
        case missingToken
    }

    private let networkClient: AsyncNetworkClient
    private let tokenStorageService: TokenStorageServiceProtocol

    private var refreshTask: Task<AuthTokenDTO, Swift.Error>?

    init(
        networkClient: AsyncNetworkClient,
        tokenStorageService: TokenStorageServiceProtocol
    ) {
        self.networkClient = networkClient
        self.tokenStorageService = tokenStorageService
    }

    func hasValidSession() async -> Bool {
        guard let token = tokenStorageService.getToken() else {
            return false
        }

        if !isTokenExpired(token) {
            return true
        }

        do {
            _ = try await refreshAccessToken()
            return true
        } catch {
            return false
        }
    }

    func refreshAccessToken() async throws -> AuthTokenDTO {
        if let refreshTask {
            return try await refreshTask.value
        }

        guard let token = tokenStorageService.getToken() else {
            throw Error.missingToken
        }

        let refreshTask = Task<AuthTokenDTO, Swift.Error> { [networkClient, tokenStorageService] in
            do {
                let tokenResponse = try await networkClient.request(
                    AuthAPI.refresh(
                        AuthTokenRequestDTO(refreshToken: token.refreshToken)
                    ),
                    responseType: AuthTokenDTO.self
                )
                let persistedToken = tokenResponse.withIssuedAt(Date().timeIntervalSince1970)
                tokenStorageService.setToken(persistedToken)
                return persistedToken
            } catch {
                tokenStorageService.removeToken()
                NotificationCenter.default.post(name: .authSessionDidLogout, object: nil)
                throw error
            }
        }

        self.refreshTask = refreshTask
        defer { self.refreshTask = nil }
        return try await refreshTask.value
    }

    func accessToken() async -> String? {
        tokenStorageService.getToken()?.accessToken
    }

    func logout() async {
        tokenStorageService.removeToken()
        NotificationCenter.default.post(name: .authSessionDidLogout, object: nil)
    }
}

private extension AuthSessionService {
    func isTokenExpired(_ token: AuthTokenDTO) -> Bool {
        guard let issuedAt = token.issuedAt else {
            return true
        }

        let expirationTimestamp = issuedAt + TimeInterval(max(0, token.expiresIn))
        return Date().timeIntervalSince1970 >= expirationTimestamp
    }
}
