// Created by Egor Shkarin 09.04.2026

import Foundation

protocol SubscriptionTransactionObserverServiceProtocol: Sendable {
    func start()
}

final class SubscriptionTransactionObserverService: SubscriptionTransactionObserverServiceProtocol, @unchecked Sendable {
    private let storeKitService: SubscriptionStoreKitServicing
    private let contractService: SubscriptionContractServicing

    private let lock = NSLock()
    private var observationTask: Task<Void, Never>?

    init(
        storeKitService: SubscriptionStoreKitServicing,
        contractService: SubscriptionContractServicing
    ) {
        self.storeKitService = storeKitService
        self.contractService = contractService
    }

    deinit {
        observationTask?.cancel()
    }

    func start() {
        let updatesStream = storeKitService.makeTransactionUpdatesStream()
        let task = lock.withLock { () -> Task<Void, Never>? in
            guard observationTask == nil else {
                return nil
            }

            let observationTask = Task { [storeKitService, contractService] in
                for await purchase in updatesStream {
                    do {
                        try await contractService.approvePurchase(.init(purchase: purchase))
                        try await storeKitService.finishPurchase(transactionID: purchase.transactionId)
                    } catch {
                        continue
                    }
                }
            }

            self.observationTask = observationTask
            return observationTask
        }

        _ = task
    }
}

private extension NSLock {
    func withLock<T>(_ block: () -> T) -> T {
        lock()
        defer { unlock() }
        return block()
    }
}
