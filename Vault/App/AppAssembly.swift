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
        regiaterNetworkClient(with: container)
        registerServices(with: container)
    }
}

// MARK: Private
private extension AppAssembly {
    func regiaterNetworkClient(with container: Container) {
        // TODO: Add auth interceptor and default request headers
        container.register(NetworkClient.self) { _ in
            NetworkClientFactory().buildClient(
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
        .inObjectScope(.container)

        container.register(ToastPresenting.self) { _ in
            ToastPresenter()
        }
        .inObjectScope(.container)
    }
}
