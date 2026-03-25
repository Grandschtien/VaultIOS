//
//  UserProfileStorageService.swift
//  Vault
//
//  Created by Egor Shkarin on 25.03.2026.
//

import Foundation

struct UserProfileDefaults: Codable, Equatable, Sendable {
    let userId: String
    let email: String
    let name: String
    let currency: String
    let language: String
}

protocol UserProfileStorageServiceProtocol: Sendable {
    func saveProfile(_ profile: UserProfileDefaults)
    func loadProfile() -> UserProfileDefaults?
    func clearProfile()
}

final class UserProfileStorageService: UserProfileStorageServiceProtocol, @unchecked Sendable {
    private enum Constants {
        static let profileKey: String = "auth.profile.defaults"
    }

    private let storage: KeyValueStorage

    init(storage: KeyValueStorage = UserDefaultsStorage()) {
        self.storage = storage
    }

    func saveProfile(_ profile: UserProfileDefaults) {
        storage.set(profile, forKey: Constants.profileKey)
    }

    func loadProfile() -> UserProfileDefaults? {
        storage.get(UserProfileDefaults.self, forKey: Constants.profileKey)
    }

    func clearProfile() {
        storage.removeValue(forKey: Constants.profileKey)
    }
}

extension UserProfileDefaults {
    init(user: User) {
        self.init(
            userId: user.id,
            email: user.email,
            name: user.name,
            currency: user.currency,
            language: user.preferredLanguage
        )
    }
}
