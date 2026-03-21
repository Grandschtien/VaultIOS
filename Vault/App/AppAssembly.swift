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
        .inObjectScope(.container)
    }

    func registerServices(with container: Container) {
        container.register(TokenStorageServiceProtocol.self) { _ in
            TokenStorageService()
        }
        .inObjectScope(.container)

        container.register(AsyncNetworkClient.self, name: DependencyName.refreshNetworkClient) { _ in
            NetworkClientFactory().buildClient(
                urlSessionConfiguration: .default
            )
        }
        .inObjectScope(.container)

        container.register(AuthSessionServiceProtocol.self) { resolver in
            guard let refreshNetworkClient = resolver.resolve(
                AsyncNetworkClient.self,
                name: DependencyName.refreshNetworkClient
            ),
            let tokenStorageService = resolver.resolve(TokenStorageServiceProtocol.self) else {
                fatalError("Failed to resolve dependencies for AuthSessionService")
            }

            return AuthSessionService(
                networkClient: refreshNetworkClient,
                tokenStorageService: tokenStorageService
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
        .inObjectScope(.container)

        container.register(ToastPresenting.self) { _ in
            ToastPresenter()
        }
        .inObjectScope(.container)
    }
}
