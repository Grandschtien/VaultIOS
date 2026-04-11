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
    private let storeKitService: SubscriptionStoreKitServicing
    private let contractService: SubscriptionContractServicing

    private var loadingState: LoadingStatus = .idle
    private var plans: [SubscriptionStorePlan] = []
    private var purchasingPlanID: String?

    init(
        presenter: SubscriptionPresentationLogic,
        router: SubscriptionRoutingLogic,
        currentTier: String,
        output: SubscriptionOutput,
        storeKitService: SubscriptionStoreKitServicing,
        contractService: SubscriptionContractServicing
    ) {
        self.presenter = presenter
        self.router = router
        self.currentTier = currentTier
        self.output = output
        self.storeKitService = storeKitService
        self.contractService = contractService
    }

    func fetchData() async {
        loadingState = .loading
        plans = []
        purchasingPlanID = nil
        await presentFetchedData()

        do {
            plans = try await storeKitService.loadPlans()
            loadingState = .loaded
            await presentFetchedData()
        } catch {
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

        purchasingPlanID = planID
        await presentFetchedData()

        do {
            let result = try await storeKitService.purchase(planID: planID)

            switch result {
            case let .verified(purchase):
                do {
                    try await contractService.approvePurchase(.init(purchase: purchase))
                    try await storeKitService.finishPurchase(transactionID: purchase.transactionId)
                    purchasingPlanID = nil
                    await presentFetchedData()
                    await router.close()
                    await output.handleSubscriptionDidSync()
                } catch {
                    purchasingPlanID = nil
                    await presentFetchedData()
                    await router.presentError(with: syncFailedMessage(from: error))
                }

            case .pending:
                purchasingPlanID = nil
                await presentFetchedData()
                await router.presentMessage(with: L10n.subscriptionPurchasePending)

            case .cancelled:
                purchasingPlanID = nil
                await presentFetchedData()

            case .unverified:
                purchasingPlanID = nil
                await presentFetchedData()
                await router.presentError(with: L10n.subscriptionPurchaseUnverified)
            }
        } catch {
            purchasingPlanID = nil
            await presentFetchedData()
            await router.presentError(with: purchaseFailedMessage(from: error))
        }
    }
}
