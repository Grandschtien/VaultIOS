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
    func handleTapTermsOfUse() async
    func handleTapPrivacyPolicy() async
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
    private let appLogService: AppLogServiceProtocol?
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
        analytics: SubscriptionAnalyticsTracking? = nil,
        appLogService: AppLogServiceProtocol? = nil
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
        self.appLogService = appLogService
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

    func pollPurchasedTier(
        for planID: String,
        flow: String,
        subscriptionAttemptID: String
    ) async -> Bool {
        guard maximumPollingAttempts > 0 else {
            logSubscriptionEvent(
                name: "\(flow)_sync_result",
                payload: [
                    "result": "timeout",
                    "plan_id": planID,
                    "attempt_count": 0
                ],
                subscriptionAttemptID: subscriptionAttemptID
            )
            return false
        }

        for attempt in 0..<maximumPollingAttempts {
            let tierState = await subscriptionAccessService.refreshCurrentTierSourceState()

            if case .network(let tier) = tierState,
               SubscriptionPlanResolver.matchesPurchasedPlan(planID: planID, tier: tier.rawValue) {
                logSubscriptionEvent(
                    name: "\(flow)_sync_result",
                    payload: [
                        "result": "success",
                        "plan_id": planID,
                        "resolved_tier": tier.rawValue,
                        "attempt_count": attempt + 1
                    ],
                    subscriptionAttemptID: subscriptionAttemptID
                )
                return true
            }

            guard attempt < maximumPollingAttempts - 1,
                  pollingIntervalNanoseconds > .zero else {
                continue
            }

            try? await Task.sleep(nanoseconds: pollingIntervalNanoseconds)
        }

        logSubscriptionEvent(
            name: "\(flow)_sync_result",
            payload: [
                "result": "timeout",
                "plan_id": planID,
                "attempt_count": maximumPollingAttempts
            ],
            subscriptionAttemptID: subscriptionAttemptID
        )
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

    func logSubscriptionEvent(
        name: String,
        payload: [String: Any],
        subscriptionAttemptID: String
    ) {
        appLogService?.log(
            category: .subscription,
            name: name,
            source: "SubscriptionInteractor",
            payload: payload,
            requestID: nil,
            subscriptionAttemptID: subscriptionAttemptID
        )
    }

    func resolvedRevenueCatResultName(from error: Error) -> String {
        if let subscriptionError = error as? SubscriptionServiceError,
           subscriptionError == .purchaseCancelled {
            return "cancelled"
        }

        return "failure"
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

        let subscriptionAttemptID = UUID().uuidString.lowercased()
        let planTitle = plans.first(where: { $0.id == planID })?.title ?? SubscriptionCatalog.title(for: planID)
        logSubscriptionEvent(
            name: "purchase_start",
            payload: [
                "plan_id": planID,
                "plan_title": planTitle,
                "current_tier": currentTier.rawValue
            ],
            subscriptionAttemptID: subscriptionAttemptID
        )
        analytics?.trackPurchaseStart(planID: planID, planTitle: planTitle, currentTier: currentTier.rawValue)
        purchasingPlanID = planID
        await presentFetchedData()

        do {
            try await storeKitService.purchase(planID: planID)
            logSubscriptionEvent(
                name: "purchase_revenuecat_result",
                payload: [
                    "result": "success",
                    "plan_id": planID
                ],
                subscriptionAttemptID: subscriptionAttemptID
            )
            analytics?.trackPurchaseSuccess(planID: planID, planTitle: planTitle, currentTier: currentTier.rawValue)
            isPurchaseSyncing = true
            await presentFetchedData()

            if await pollPurchasedTier(
                for: planID,
                flow: "purchase",
                subscriptionAttemptID: subscriptionAttemptID
            ) {
                logSubscriptionEvent(
                    name: "purchase_outcome",
                    payload: [
                        "result": "success",
                        "plan_id": planID
                    ],
                    subscriptionAttemptID: subscriptionAttemptID
                )
                await output.handleSubscriptionDidSync()
                await router.close()
                await router.presentSuccess(with: subscriptionReadyMessage())
                return
            }

            logSubscriptionEvent(
                name: "purchase_outcome",
                payload: [
                    "result": "timeout",
                    "plan_id": planID
                ],
                subscriptionAttemptID: subscriptionAttemptID
            )
            await router.close()
            await router.presentError(with: subscriptionReloadRequiredMessage())
        } catch {
            purchasingPlanID = nil
            isPurchaseSyncing = false
            await presentFetchedData()
            logSubscriptionEvent(
                name: "purchase_revenuecat_result",
                payload: [
                    "result": resolvedRevenueCatResultName(from: error),
                    "plan_id": planID,
                    "error_description": error.localizedDescription
                ],
                subscriptionAttemptID: subscriptionAttemptID
            )
            logSubscriptionEvent(
                name: "purchase_outcome",
                payload: [
                    "result": resolvedRevenueCatResultName(from: error),
                    "plan_id": planID,
                    "error_description": error.localizedDescription
                ],
                subscriptionAttemptID: subscriptionAttemptID
            )
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

        let subscriptionAttemptID = UUID().uuidString.lowercased()
        logSubscriptionEvent(
            name: "restore_start",
            payload: [
                "current_tier": currentTier.rawValue
            ],
            subscriptionAttemptID: subscriptionAttemptID
        )
        isRestoringPurchase = true
        await presentFetchedData()

        do {
            try await storeKitService.restore()
            logSubscriptionEvent(
                name: "restore_revenuecat_result",
                payload: [
                    "result": "success"
                ],
                subscriptionAttemptID: subscriptionAttemptID
            )

            guard let restoredPlanID = restoredPlanID() else {
                isRestoringPurchase = false
                await presentFetchedData()
                logSubscriptionEvent(
                    name: "restore_outcome",
                    payload: [
                        "result": "not_found"
                    ],
                    subscriptionAttemptID: subscriptionAttemptID
                )
                await router.presentMessage(with: restoreNotFoundMessage())
                return
            }

            if await pollPurchasedTier(
                for: restoredPlanID,
                flow: "restore",
                subscriptionAttemptID: subscriptionAttemptID
            ) {
                logSubscriptionEvent(
                    name: "restore_outcome",
                    payload: [
                        "result": "success",
                        "plan_id": restoredPlanID
                    ],
                    subscriptionAttemptID: subscriptionAttemptID
                )
                await output.handleSubscriptionDidSync()
                await router.close()
                await router.presentSuccess(with: subscriptionRestoredMessage())
                return
            }

            logSubscriptionEvent(
                name: "restore_outcome",
                payload: [
                    "result": "timeout",
                    "plan_id": restoredPlanID
                ],
                subscriptionAttemptID: subscriptionAttemptID
            )
            await router.close()
            await router.presentError(with: subscriptionReloadRequiredMessage())
        } catch {
            isRestoringPurchase = false
            await presentFetchedData()
            logSubscriptionEvent(
                name: "restore_revenuecat_result",
                payload: [
                    "result": "failure",
                    "error_description": error.localizedDescription
                ],
                subscriptionAttemptID: subscriptionAttemptID
            )
            logSubscriptionEvent(
                name: "restore_outcome",
                payload: [
                    "result": "failure",
                    "error_description": error.localizedDescription
                ],
                subscriptionAttemptID: subscriptionAttemptID
            )
            await router.presentError(with: restoreFailedMessage(from: error))
        }
    }

    func handleTapTermsOfUse() async {
        guard purchasingPlanID == nil,
              !isPurchaseSyncing,
              !isRestoringPurchase else {
            return
        }

        await router.openTermsOfUse()
    }

    func handleTapPrivacyPolicy() async {
        guard purchasingPlanID == nil,
              !isPurchaseSyncing,
              !isRestoringPurchase else {
            return
        }

        await router.openPrivacyPolicy()
    }
}
