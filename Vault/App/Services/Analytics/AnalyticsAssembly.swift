import Swinject

struct AnalyticsAssembly: Assembly {
    func assemble(container: Container) {
        container.register(FirebaseAnalyticsService.self) { _ in
            FirebaseAnalyticsService()
        }
        .inObjectScope(.container)

        container.register(AppLogSinkProtocol.self) { _ in
            RotatingFileAppLogSink()
        }
        .inObjectScope(.transient)

        container.register(AppLogServiceProtocol.self) { _ in
#if DEBUG
            return AppLogService(sinks: [ConsoleAppLogSink()])
#else
            return AppLogService(sinks: [RotatingFileAppLogSink()])
#endif
        }
        .inObjectScope(.container)

        container.register(AnalyticsFailurePayloadResolving.self) { _ in
            AnalyticsFailurePayloadResolver()
        }
        .inObjectScope(.transient)

        container.register(AnalyticsCoreManager.self) { resolver in
            guard let firebaseService = resolver.resolve(FirebaseAnalyticsService.self),
                  let appLogService = resolver.resolve(AppLogServiceProtocol.self) else {
                fatalError("Failed to resolve dependencies for AnalyticsCoreManager")
            }

            return AnalyticsCoreManager(
                services: [firebaseService],
                userProfileStorageService: resolver.resolve(UserProfileStorageServiceProtocol.self),
                appLogService: appLogService
            )
        }
        .implements(AnalyticsCoreManaging.self)
        .inObjectScope(.container)
    }
}
