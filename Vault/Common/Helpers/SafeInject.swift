//
//  SafeInjected.swift
//  Vault
//
//  Created by Егор Шкарин on 14.03.2026.
//

import Swinject
import Foundation

@propertyWrapper
struct SafeInject<Service> {
    private let resolver: Resolver
    private var service: Service

    init(resolver: Resolver = DI.resolver) {
        self.resolver = resolver

        guard let resolved = resolver.resolve(Service.self) else {
            fatalError("Dependency \(Service.self) is not registered in Swinject container")
        }

        self.service = resolved
    }

    var wrappedValue: Service {
        service
    }
}
