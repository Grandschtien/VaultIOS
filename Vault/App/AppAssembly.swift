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
        AnalyticsAssembly().assemble(container: container)
        registerServices(with: container)
        regiaterNetworkClient(with: container)
    }
}

// MARK: Private
private extension AppAssembly {
    enum DependencyName {
        static let refreshNetworkClient = "auth.refresh.networkClient"
    }

    enum ConfigurationKey {
        static let revenueCatAPIKey = "RevenueCatAPIKey"
        static let revenueCatEnvironmentKey = "REVENUECAT_API_KEY"
    }

    func regiaterNetworkClient(with container: Container) {
        container.register(NetworkClient.self) { resolver in
            guard let authInterceptor = resolver.resolve(AuthInterceptor.self),
                  let retryInterceptor = resolver.resolve(RetryInterceptor.self),
                  let appLogService = resolver.resolve(AppLogServiceProtocol.self)
            else {
                fatalError("Failed to resolve auth interceptors for network client")
            }

            return NetworkClientFactory().buildClient(
                interceptors: [retryInterceptor],
                adapters: [authInterceptor],
                networkLogger: RedactingNetworkCallLogger(appLogService: appLogService),
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

        container.register(VaultRouteParsing.self) { _ in
            VaultRouteParser()
        }
        .inObjectScope(.transient)

        container.register(PendingVaultRouteStoring.self) { _ in
            PendingVaultRouteStore()
        }
        .inObjectScope(.container)

        container.register(VaultWidgetSnapshotStoring.self) { _ in
            VaultWidgetSnapshotStorage()
        }
        .inObjectScope(.transient)

        container.register(VaultWidgetTimelineReloading.self) { _ in
            VaultWidgetTimelineReloader()
        }
        .inObjectScope(.transient)

        container.register(VaultWidgetEntryDestinationResolving.self) { resolver in
            guard let subscriptionAccessService = resolver.resolve(SubscriptionAccessServicing.self) else {
                fatalError("Failed to resolve SubscriptionAccessService for VaultWidgetEntryDestinationResolver")
            }

            return VaultWidgetEntryDestinationResolver(
                subscriptionAccessService: subscriptionAccessService
            )
        }
        .inObjectScope(.transient)

        container.register(AsyncNetworkClient.self, name: DependencyName.refreshNetworkClient) { resolver in
            guard let appLogService = resolver.resolve(AppLogServiceProtocol.self) else {
                fatalError("Failed to resolve AppLogService for refresh AsyncNetworkClient")
            }

            return NetworkClientFactory().buildClient(
                networkLogger: RedactingNetworkCallLogger(appLogService: appLogService),
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

        container.register(PasswordRestorationContractServicing.self) { resolver in
            guard let networkClient = resolver.resolve(AsyncNetworkClient.self) else {
                fatalError("Failed to resolve AsyncNetworkClient for PasswordRestorationContractService")
            }

            return PasswordRestorationContractService(networkClient: networkClient)
        }
        .inObjectScope(.transient)

        container.register(AuthVerificationContractServicing.self) { resolver in
            guard let networkClient = resolver.resolve(AsyncNetworkClient.self) else {
                fatalError("Failed to resolve AsyncNetworkClient for AuthVerificationContractService")
            }

            return AuthVerificationContractService(networkClient: networkClient)
        }
        .inObjectScope(.transient)

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

        container.register(VaultWidgetSnapshotSyncing.self) { resolver in
            guard let summaryService = resolver.resolve(MainSummaryContractServicing.self),
                  let storage = resolver.resolve(VaultWidgetSnapshotStoring.self),
                  let timelineReloader = resolver.resolve(VaultWidgetTimelineReloading.self) else {
                fatalError("Failed to resolve dependencies for VaultWidgetSnapshotSyncService")
            }

            return VaultWidgetSnapshotSyncService(
                summaryService: summaryService,
                storage: storage,
                timelineReloader: timelineReloader
            )
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

        container.register(ExpenseAIEntryVoiceRecordingServicing.self) { resolver in
            guard let userProfileStorageService = resolver.resolve(UserProfileStorageServiceProtocol.self) else {
                fatalError("Failed to resolve UserProfileStorageService for ExpenseAIEntryVoiceRecordingService")
            }

            return ExpenseAIEntryVoiceRecordingService(
                userProfileStorageService: userProfileStorageService
            )
        }
        .inObjectScope(.transient)

        container.register(ProfileContractServicing.self) { resolver in
            guard let networkClient = resolver.resolve(AsyncNetworkClient.self) else {
                fatalError("Failed to resolve AsyncNetworkClient for ProfileContractService")
            }

            return ProfileContractService(networkClient: networkClient)
        }
        .inObjectScope(.container)

        container.register(SubscriptionAccessContractServicing.self) { resolver in
            guard let networkClient = resolver.resolve(AsyncNetworkClient.self) else {
                fatalError("Failed to resolve AsyncNetworkClient for SubscriptionAccessContractService")
            }

            return SubscriptionAccessContractService(networkClient: networkClient)
        }
        .inObjectScope(.container)

        container.register(SubscriptionAppAccountTokenProviding.self) { resolver in
            guard let userProfileStorageService = resolver.resolve(UserProfileStorageServiceProtocol.self) else {
                fatalError("Failed to resolve UserProfileStorageService for SubscriptionAppAccountTokenProvider")
            }

            return SubscriptionAppAccountTokenProvider(
                userProfileStorageService: userProfileStorageService
            )
        }
        .inObjectScope(.transient)


        container.register(SubscriptionAccessServicing.self) { resolver in
            guard let subscriptionService = resolver.resolve(SubscriptionAccessContractServicing.self),
                  let userProfileStorageService = resolver.resolve(UserProfileStorageServiceProtocol.self) else {
                fatalError("Failed to resolve dependencies for SubscriptionAccessService")
            }

            return SubscriptionAccessService(
                subscriptionService: subscriptionService,
                userProfileStorageService: userProfileStorageService
            )
        }
        .inObjectScope(.container)
        
        container.register(SubscriptionInitializerLogic.self) { resolver in
            let profile = resolver.resolve(ProfileContractServicing.self)!
            return SubscriptionInitializer(
                apiKey: resolvedRevenueCatAPIKey(),
                profileService: profile
            )
        }
        .inObjectScope(.container)
        
        container.register(SubscriptionServiceLogic.self) { resolver in
            guard let appLogService = resolver.resolve(AppLogServiceProtocol.self) else {
                fatalError("Failed to resolve AppLogService for SubscriptionService")
            }

            return SubscriptionService(appLogService: appLogService)
        }
        .inObjectScope(.transient)
        
        container.register(SubscriptionUpdatesListenerLogic.self) { resolver in
            return SubscriptionUpdatesListener()
        }
        .inObjectScope(.container)
        
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
        .inObjectScope(.container)
    }

    func resolvedRevenueCatAPIKey() -> String {
        if let environmentValue = ProcessInfo.processInfo.environment[ConfigurationKey.revenueCatEnvironmentKey],
           !environmentValue.isEmpty {
            return environmentValue
        }

        if let infoDictionaryValue = Bundle.main.object(
            forInfoDictionaryKey: ConfigurationKey.revenueCatAPIKey
        ) as? String,
           !infoDictionaryValue.isEmpty,
           !infoDictionaryValue.hasPrefix("$(") {
            return infoDictionaryValue
        }

        fatalError(
            "RevenueCat API key is missing. Set REVENUECAT_API_KEY in the environment or provide RevenueCatAPIKey in Info.plist."
        )
    }
}
