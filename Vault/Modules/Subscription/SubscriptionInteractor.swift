// Created by Egor Shkarin 08.04.2026

import Foundation

protocol SubscriptionBusinessLogic: Sendable {
    func fetchData() async
}

protocol SubscriptionHandler: AnyObject, Sendable {
    func handleTapClose() async
    func handleTapRetry() async
    func handleTapPurchase(planID: String) async
}

protocol SubscriptionOutput: AnyObject, Sendable {
    func handleSubscriptionDidSync() async
}

actor SubscriptionInteractor: SubscriptionBusinessLogic {
    private let presenter: SubscriptionPresentationLogic
    private let router: SubscriptionRoutingLogic
    private let currentTier: String
    private let output: SubscriptionOutput
    private let storeKitService: SubscriptionServiceLogic
    private let analytics: SubscriptionAnalyticsTracking?

    private var loadingState: LoadingStatus = .idle
    private var hasTrackedScreenOpen: Bool = false
    private var plans: [SubscriptionFetchData.SubscriptionStorePlan] = []
    private var purchasingPlanID: String?

    init(
        presenter: SubscriptionPresentationLogic,
        router: SubscriptionRoutingLogic,
        currentTier: String,
        output: SubscriptionOutput,
        storeKitService: SubscriptionServiceLogic,
        analytics: SubscriptionAnalyticsTracking? = nil
    ) {
        self.presenter = presenter
        self.router = router
        self.currentTier = currentTier
        self.output = output
        self.storeKitService = storeKitService
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
        await presentFetchedData()

        do {
            plans = try await storeKitService.loadPlans()
            loadingState = .loaded
            await presentFetchedData()
            analytics?.trackSubscriptionSuccess(plans: plans, currentTier: currentTier)
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
                currentTier: currentTier,
                plans: plans,
                purchasingPlanID: purchasingPlanID
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

    func fallbackMessage(from error: Error, defaultMessage: String) -> String {
        let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return message.isEmpty ? defaultMessage : message
    }
}

extension SubscriptionInteractor: SubscriptionHandler {
    func handleTapClose() async {
        guard purchasingPlanID == nil else {
            return
        }

        await router.close()
    }

    func handleTapRetry() async {
        await fetchData()
    }

    func handleTapPurchase(planID: String) async {
        guard loadingState == .loaded,
              purchasingPlanID == nil else {
            return
        }

        let planTitle = plans.first(where: { $0.id == planID })?.title ?? SubscriptionCatalog.title(for: planID)
        analytics?.trackPurchaseStart(planID: planID, planTitle: planTitle, currentTier: currentTier)
        purchasingPlanID = planID
        await presentFetchedData()

        do {
            try await storeKitService.purchase(planID: planID)
            await presentFetchedData()
            analytics?.trackPurchaseSuccess(planID: planID, planTitle: planTitle, currentTier: currentTier)
            await router.close()
        } catch {
            purchasingPlanID = nil
            await presentFetchedData()
            analytics?.trackPurchaseFailure(
                planID: planID,
                planTitle: planTitle,
                currentTier: currentTier,
                error: error
            )
            await router.presentError(with: purchaseFailedMessage(from: error))
        }
    }
}
