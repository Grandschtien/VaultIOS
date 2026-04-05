//
//  AppAssembly.swift
//  Vault
//
//  Created by Егор Шкарин on 14.03.2026.
//

import Swinject
import Foundation
import NetworkClient

struct AppAssembly: Assembly {
    func assemble(container: Container) {
        registerServices(with: container)
        regiaterNetworkClient(with: container)
    }
}

// MARK: Private
private extension AppAssembly {
    enum DependencyName {
        static let refreshNetworkClient = "auth.refresh.networkClient"
    }

    func regiaterNetworkClient(with container: Container) {
        container.register(NetworkClient.self) { resolver in
            guard let authInterceptor = resolver.resolve(AuthInterceptor.self),
                  let retryInterceptor = resolver.resolve(RetryInterceptor.self)
            else {
                fatalError("Failed to resolve auth interceptors for network client")
            }

            return NetworkClientFactory().buildClient(
                interceptors: [retryInterceptor],
                adapters: [authInterceptor],
                urlSessionConfiguration: .default
            )
        }
        .implements(AsyncNetworkClient.self)
        .inObjectScope(.transient)
    }

    func registerServices(with container: Container) {
        container.register(TokenStorageServiceProtocol.self) { _ in
            TokenStorageService()
        }
        .inObjectScope(.transient)

        container.register(FirstRunKeychainCleanupServiceProtocol.self) { _ in
            FirstRunKeychainCleanupService()
        }
        .inObjectScope(.transient)

        container.register(UserProfileStorageServiceProtocol.self) { _ in
            UserProfileStorageService()
        }
        .inObjectScope(.transient)

        container.register(AsyncNetworkClient.self, name: DependencyName.refreshNetworkClient) { _ in
            NetworkClientFactory().buildClient(
                urlSessionConfiguration: .default
            )
        }
        .inObjectScope(.transient)

        container.register(AuthSessionServiceProtocol.self) { resolver in
            guard let refreshNetworkClient = resolver.resolve(
                AsyncNetworkClient.self,
                name: DependencyName.refreshNetworkClient
            ),
            let tokenStorageService = resolver.resolve(TokenStorageServiceProtocol.self),
            let userProfileStorageService = resolver.resolve(UserProfileStorageServiceProtocol.self) else {
                fatalError("Failed to resolve dependencies for AuthSessionService")
            }

            return AuthSessionService(
                networkClient: refreshNetworkClient,
                tokenStorageService: tokenStorageService,
                userProfileStorageService: userProfileStorageService
            )
        }
        .inObjectScope(.container)

        container.register(AuthInterceptor.self) { resolver in
            guard let authSessionService = resolver.resolve(AuthSessionServiceProtocol.self) else {
                fatalError("Failed to resolve AuthSessionService for AuthInterceptor")
            }

            return AuthInterceptor(authSessionService: authSessionService)
        }
        .inObjectScope(.container)

        container.register(RetryInterceptor.self) { resolver in
            guard let authSessionService = resolver.resolve(AuthSessionServiceProtocol.self) else {
                fatalError("Failed to resolve AuthSessionService for RetryInterceptor")
            }

            return RetryInterceptor(authSessionService: authSessionService)
        }
        .inObjectScope(.transient)

        container.register(MainSummaryContractServicing.self) { resolver in
            guard let networkClient = resolver.resolve(AsyncNetworkClient.self) else {
                fatalError("Failed to resolve AsyncNetworkClient for MainSummaryContractService")
            }

            return MainSummaryContractService(networkClient: networkClient)
        }
        .inObjectScope(.transient)

        container.register(MainCurrencyRateContractServicing.self) { resolver in
            guard let networkClient = resolver.resolve(AsyncNetworkClient.self) else {
                fatalError("Failed to resolve AsyncNetworkClient for MainCurrencyRateContractService")
            }

            return MainCurrencyRateContractService(networkClient: networkClient)
        }
        .inObjectScope(.transient)

        container.register(MainCategoriesContractServicing.self) { resolver in
            guard let networkClient = resolver.resolve(AsyncNetworkClient.self) else {
                fatalError("Failed to resolve AsyncNetworkClient for MainCategoriesContractService")
            }

            return MainCategoriesContractService(networkClient: networkClient)
        }
        .inObjectScope(.transient)

        container.register(MainExpensesContractServicing.self) { resolver in
            guard let networkClient = resolver.resolve(AsyncNetworkClient.self) else {
                fatalError("Failed to resolve AsyncNetworkClient for MainExpensesContractService")
            }

            return MainExpensesContractService(networkClient: networkClient)
        }
        .inObjectScope(.transient)

        container.register(MainAIParseContractServicing.self) { resolver in
            guard let networkClient = resolver.resolve(AsyncNetworkClient.self) else {
                fatalError("Failed to resolve AsyncNetworkClient for MainAIParseContractService")
            }

            return MainAIParseContractService(networkClient: networkClient)
        }
        .inObjectScope(.transient)

        container.register(ProfileContractServicing.self) { resolver in
            guard let networkClient = resolver.resolve(AsyncNetworkClient.self) else {
                fatalError("Failed to resolve AsyncNetworkClient for ProfileContractService")
            }

            return ProfileContractService(networkClient: networkClient)
        }
        .inObjectScope(.transient)

        container.register(UserCurrencyConverting.self) { resolver in
            guard let userProfileStorageService = resolver.resolve(UserProfileStorageServiceProtocol.self) else {
                fatalError("Failed to resolve UserProfileStorageService for UserCurrencyConversionService")
            }

            return UserCurrencyConversionService(
                userProfileStorageService: userProfileStorageService
            )
        }
        .inObjectScope(.transient)

        container.register(ToastPresenting.self) { _ in
            ToastPresenter()
        }
        .inObjectScope(.transient)
    }
}
