// Created by Egor Shkarin 08.04.2026

import Foundation

protocol SubscriptionBusinessLogic: Sendable {
    func fetchData() async
}

protocol SubscriptionHandler: AnyObject, Sendable {
    func handleTapClose() async
    func handleTapRetry() async
    func handleTapPurchase(planID: String) async
    func handleTapRestorePurchase() async
}

protocol SubscriptionOutput: AnyObject, Sendable {
    func handleSubscriptionDidSync() async
}

actor SubscriptionInteractor: SubscriptionBusinessLogic {
    private enum Constants {
        static let pollingIntervalNanoseconds: UInt64 = 1_000_000_000
        static let maximumPollingAttempts = 30
    }

    private let presenter: SubscriptionPresentationLogic
    private let router: SubscriptionRoutingLogic
    private let currentTier: SubscriptionTier
    private let output: SubscriptionOutput
    private let storeKitService: SubscriptionServiceLogic
    private let subscriptionAccessService: SubscriptionAccessServicing
    private let analytics: SubscriptionAnalyticsTracking?
    private let pollingIntervalNanoseconds: UInt64
    private let maximumPollingAttempts: Int

    private var loadingState: LoadingStatus = .idle
    private var hasTrackedScreenOpen: Bool = false
    private var plans: [SubscriptionFetchData.SubscriptionStorePlan] = []
    private var purchasingPlanID: String?
    private var isPurchaseSyncing = false
    private var isRestoringPurchase = false

    init(
        presenter: SubscriptionPresentationLogic,
        router: SubscriptionRoutingLogic,
        currentTier: SubscriptionTier,
        output: SubscriptionOutput,
        storeKitService: SubscriptionServiceLogic,
        subscriptionAccessService: SubscriptionAccessServicing,
        pollingIntervalNanoseconds: UInt64 = Constants.pollingIntervalNanoseconds,
        maximumPollingAttempts: Int = Constants.maximumPollingAttempts,
        analytics: SubscriptionAnalyticsTracking? = nil
    ) {
        self.presenter = presenter
        self.router = router
        self.currentTier = currentTier
        self.output = output
        self.storeKitService = storeKitService
        self.subscriptionAccessService = subscriptionAccessService
        self.pollingIntervalNanoseconds = pollingIntervalNanoseconds
        self.maximumPollingAttempts = maximumPollingAttempts
        self.analytics = analytics
    }

    func fetchData() async {
        if !hasTrackedScreenOpen {
            analytics?.trackScreenOpen()
            hasTrackedScreenOpen = true
        }
        loadingState = .loading
        plans = []
        purchasingPlanID = nil
        isPurchaseSyncing = false
        isRestoringPurchase = false
        await presentFetchedData()

        do {
            plans = try await storeKitService.loadPlans()
            loadingState = .loaded
            await presentFetchedData()
            analytics?.trackSubscriptionSuccess(plans: plans, currentTier: currentTier.rawValue)
        } catch {
            analytics?.trackSubscriptionFailure(error)
            loadingState = .failed(.undelinedError(description: loadFailedMessage(from: error)))
            await presentFetchedData()
        }
    }
}

private extension SubscriptionInteractor {
    func presentFetchedData() async {
        await presenter.presentFetchedData(
            .init(
                loadingState: loadingState,
                currentTier: currentTier.rawValue,
                plans: plans,
                purchasingPlanID: purchasingPlanID,
                isPurchaseSyncing: isPurchaseSyncing,
                isRestoringPurchase: isRestoringPurchase
            )
        )
    }

    func loadFailedMessage(from error: Error) -> String {
        fallbackMessage(from: error, defaultMessage: L10n.subscriptionLoadingFailed)
    }

    func purchaseFailedMessage(from error: Error) -> String {
        fallbackMessage(from: error, defaultMessage: L10n.subscriptionPurchaseFailed)
    }

    func syncFailedMessage(from error: Error) -> String {
        fallbackMessage(from: error, defaultMessage: L10n.subscriptionSyncFailed)
    }

    func restoreFailedMessage(from error: Error) -> String {
        fallbackMessage(from: error, defaultMessage: L10n.subscriptionRestoreFailed)
    }

    func subscriptionReadyMessage() -> String {
        L10n.subscriptionReady
    }

    func subscriptionRestoredMessage() -> String {
        L10n.subscriptionRestored
    }

    func subscriptionReloadRequiredMessage() -> String {
        L10n.subscriptionReloadRequired
    }

    func restoreNotFoundMessage() -> String {
        L10n.subscriptionRestoreNotFound
    }

    func pollPurchasedTier(for planID: String) async -> Bool {
        guard maximumPollingAttempts > 0 else {
            return false
        }

        for attempt in 0..<maximumPollingAttempts {
            let tierState = await subscriptionAccessService.refreshCurrentTierSourceState()

            if case .network(let tier) = tierState,
               SubscriptionPlanResolver.matchesPurchasedPlan(planID: planID, tier: tier.rawValue) {
                return true
            }

            guard attempt < maximumPollingAttempts - 1,
                  pollingIntervalNanoseconds > .zero else {
                continue
            }

            try? await Task.sleep(nanoseconds: pollingIntervalNanoseconds)
        }

        return false
    }

    func fallbackMessage(from error: Error, defaultMessage: String) -> String {
        let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return message.isEmpty ? defaultMessage : message
    }

    func restoredPlanID() -> String? {
        switch storeKitService.currentTier {
        case .regular:
            return nil
        case .premium:
            return SubscriptionCatalog.premium.id
        }
    }
}

extension SubscriptionInteractor: SubscriptionHandler {
    func handleTapClose() async {
        guard purchasingPlanID == nil,
              !isPurchaseSyncing,
              !isRestoringPurchase else {
            return
        }

        await router.close()
    }

    func handleTapRetry() async {
        await fetchData()
    }

    func handleTapPurchase(planID: String) async {
        guard loadingState == .loaded,
              purchasingPlanID == nil,
              !isRestoringPurchase else {
            return
        }

        let planTitle = plans.first(where: { $0.id == planID })?.title ?? SubscriptionCatalog.title(for: planID)
        analytics?.trackPurchaseStart(planID: planID, planTitle: planTitle, currentTier: currentTier.rawValue)
        purchasingPlanID = planID
        await presentFetchedData()

        do {
            try await storeKitService.purchase(planID: planID)
            analytics?.trackPurchaseSuccess(planID: planID, planTitle: planTitle, currentTier: currentTier.rawValue)
            isPurchaseSyncing = true
            await presentFetchedData()

            if await pollPurchasedTier(for: planID) {
                await output.handleSubscriptionDidSync()
                await router.close()
                await router.presentSuccess(with: subscriptionReadyMessage())
                return
            }

            await router.close()
            await router.presentError(with: subscriptionReloadRequiredMessage())
        } catch {
            purchasingPlanID = nil
            isPurchaseSyncing = false
            await presentFetchedData()
            analytics?.trackPurchaseFailure(
                planID: planID,
                planTitle: planTitle,
                currentTier: currentTier.rawValue,
                error: error
            )
            await router.presentError(with: purchaseFailedMessage(from: error))
        }
    }

    func handleTapRestorePurchase() async {
        guard loadingState == .loaded,
              purchasingPlanID == nil,
              !isPurchaseSyncing,
              !isRestoringPurchase else {
            return
        }

        isRestoringPurchase = true
        await presentFetchedData()

        do {
            try await storeKitService.restore()

            guard let restoredPlanID = restoredPlanID() else {
                isRestoringPurchase = false
                await presentFetchedData()
                await router.presentMessage(with: restoreNotFoundMessage())
                return
            }

            if await pollPurchasedTier(for: restoredPlanID) {
                await output.handleSubscriptionDidSync()
                await router.close()
                await router.presentSuccess(with: subscriptionRestoredMessage())
                return
            }

            await router.close()
            await router.presentError(with: subscriptionReloadRequiredMessage())
        } catch {
            isRestoringPurchase = false
            await presentFetchedData()
            await router.presentError(with: restoreFailedMessage(from: error))
        }
    }
}
