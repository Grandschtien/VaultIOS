import Swinject

struct AnalyticsAssembly: Assembly {
    func assemble(container: Container) {
        container.register(FirebaseAnalyticsService.self) { _ in
            FirebaseAnalyticsService()
        }
        .inObjectScope(.container)

        container.register(AnalyticsFailurePayloadResolving.self) { _ in
            AnalyticsFailurePayloadResolver()
        }
        .inObjectScope(.transient)

        container.register(AnalyticsCoreManager.self) { resolver in
            guard let firebaseService = resolver.resolve(FirebaseAnalyticsService.self),
                  let userProfileStorageService = resolver.resolve(UserProfileStorageServiceProtocol.self) else {
                fatalError("Failed to resolve dependencies for AnalyticsCoreManager")
            }

            return AnalyticsCoreManager(
                services: [firebaseService],
                userProfileStorageService: userProfileStorageService
            )
        }
        .implements(AnalyticsCoreManaging.self)
        .inObjectScope(.container)
    }
}
