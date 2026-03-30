//
//  FirstRunKeychainCleanupService.swift
//  Vault
//
//  Created by Codex on 30.03.2026.
//

import Foundation

protocol FirstRunKeychainCleanupServiceProtocol {
    func clearKeychainIfNeeded()
}

final class FirstRunKeychainCleanupService: FirstRunKeychainCleanupServiceProtocol {
    private let keychainClient: KeychainClientProtocol
    private let storage: KeyValueStorage

    init(
        keychainClient: KeychainClientProtocol = KeychainClient(),
        storage: KeyValueStorage = UserDefaultsStorage()
    ) {
        self.keychainClient = keychainClient
        self.storage = storage
    }

    func clearKeychainIfNeeded() {
        guard isFirstRun else {
            return
        }

        keychainClient.removeAll()
        storage.set(false, forKey: UserDefaultKeys.isFirstRun.rawValue)
    }
}

private extension FirstRunKeychainCleanupService {
    var isFirstRun: Bool {
        storage.get(Bool.self, forKey: UserDefaultKeys.isFirstRun.rawValue) ?? true
    }
}
