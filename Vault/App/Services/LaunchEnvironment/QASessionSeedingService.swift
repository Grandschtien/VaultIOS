// Created by Egor Shkarin on 28.10.2026

import Foundation

protocol QASessionSeedingServiceProtocol {
    func seedSessionIfNeeded()
}

/// Stores the session passed in `VAULT_QA_SESSION` so QA scenarios start on the main screen without typing credentials.
final class QASessionSeedingService: QASessionSeedingServiceProtocol {
    private let launchEnvironment: LaunchEnvironmentProviding
    private let tokenStorageService: TokenStorageServiceProtocol
    private let userProfileStorageService: UserProfileStorageServiceProtocol
    private let storage: KeyValueStorage
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    init(
        launchEnvironment: LaunchEnvironmentProviding = LaunchEnvironmentProvider.shared,
        tokenStorageService: TokenStorageServiceProtocol,
        userProfileStorageService: UserProfileStorageServiceProtocol,
        storage: KeyValueStorage = UserDefaultsStorage()
    ) {
        self.launchEnvironment = launchEnvironment
        self.tokenStorageService = tokenStorageService
        self.userProfileStorageService = userProfileStorageService
        self.storage = storage
    }

    func seedSessionIfNeeded() {
        guard let rawSession = launchEnvironment.qaSession,
              let session = try? decoder.decode(LoginResponseDTO.self, from: Data(rawSession.utf8)) else {
            return
        }

        tokenStorageService.setToken(
            AuthTokenDTO(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                tokenType: session.tokenType,
                expiresIn: session.expiresIn
            )
        )
        userProfileStorageService.saveProfile(UserProfileDefaults(user: session.user))
        storage.set(true, forKey: UserDefaultKeys.isOnboardingCompleted.rawValue)
    }
}
