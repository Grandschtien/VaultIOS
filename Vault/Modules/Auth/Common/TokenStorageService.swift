//
//  TokenStorageService.swift
//  Vault
//
//  Created by Egor Shkarin on 15.03.2026.
//

import Foundation
import Security

protocol TokenStorageServiceProtocol: Sendable {
    func setToken(_ token: AuthTokenDTO)
    func getToken() -> AuthTokenDTO?
    func removeToken()
}

final class TokenStorageService: TokenStorageServiceProtocol, @unchecked Sendable {
    private let keychainClient: KeychainClientProtocol
    private let service: String
    private let tokenAccount: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        keychainClient: KeychainClientProtocol = KeychainClient(),
        service: String = Bundle.main.bundleIdentifier ?? "com.egor.shkarin.Vault",
        tokenAccount: String = "auth.tokens"
    ) {
        self.keychainClient = keychainClient
        self.service = service
        self.tokenAccount = tokenAccount
    }

    func setToken(_ token: AuthTokenDTO) {
        let preparedToken = token.issuedAt == nil
            ? token.withIssuedAt(Date().timeIntervalSince1970)
            : token

        guard let data = try? encoder.encode(preparedToken) else {
            return
        }

        keychainClient.set(data, forAccount: tokenAccount, service: service)
    }

    func getToken() -> AuthTokenDTO? {
        guard let data = keychainClient.getData(forAccount: tokenAccount, service: service) else {
            return nil
        }

        return try? decoder.decode(AuthTokenDTO.self, from: data)
    }

    func removeToken() {
        keychainClient.removeData(forAccount: tokenAccount, service: service)
    }
}
