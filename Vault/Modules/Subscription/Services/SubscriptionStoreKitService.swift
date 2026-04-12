// Created by Egor Shkarin 08.04.2026

import Foundation
@preconcurrency import StoreKit

struct SubscriptionStorePlan: Equatable, Sendable {
    let id: String
    let title: String
    let price: String
}

struct SubscriptionVerifiedPurchase: Equatable, Sendable {
    let productId: String
    let transactionId: String
    let originalTransactionId: String
    let signedTransaction: String
    let purchaseDate: Date
    let environment: String
}

enum SubscriptionPurchaseResult: Equatable, Sendable {
    case verified(SubscriptionVerifiedPurchase)
    case pending
    case cancelled
    case unverified
}

protocol SubscriptionStoreKitServicing: Sendable {
    func loadPlans() async throws -> [SubscriptionStorePlan]
    func purchase(planID: String) async throws -> SubscriptionPurchaseResult
    func finishPurchase(transactionID: String) async throws
    func makeTransactionUpdatesStream() -> AsyncStream<SubscriptionVerifiedPurchase>
}

protocol SubscriptionStoreKitClientProtocol: Sendable {
    func products(for productIDs: [String]) async throws -> [SubscriptionStoreKitClientProduct]
    func purchase(productID: String, appAccountToken: UUID) async throws -> SubscriptionPurchaseResult
    func finish(transactionID: String) async throws
    func makeTransactionUpdatesStream() -> AsyncStream<SubscriptionVerifiedPurchase>
}

struct SubscriptionStoreKitClientProduct: Equatable, Sendable {
    let id: String
    let price: String
}

final class SubscriptionStoreKitService: SubscriptionStoreKitServicing {
    private let client: SubscriptionStoreKitClientProtocol
    private let appAccountTokenProvider: SubscriptionAppAccountTokenProviding

    init(
        client: SubscriptionStoreKitClientProtocol = SubscriptionStoreKitClient(),
        appAccountTokenProvider: SubscriptionAppAccountTokenProviding
    ) {
        self.client = client
        self.appAccountTokenProvider = appAccountTokenProvider
    }

    func loadPlans() async throws -> [SubscriptionStorePlan] {
        let products = try await client.products(
            for: SubscriptionCatalog.orderedPlans.map(\.id)
        )
        let productsByID = Dictionary(
            uniqueKeysWithValues: products.map { ($0.id, $0) }
        )

        let plans: [SubscriptionStorePlan] = SubscriptionCatalog.orderedPlans.compactMap { plan -> SubscriptionStorePlan? in
            guard let product = productsByID[plan.id] else {
                return nil
            }

            return SubscriptionStorePlan(
                id: plan.id,
                title: plan.title,
                price: product.price
            )
        }

        guard plans.count == SubscriptionCatalog.orderedPlans.count else {
            throw SubscriptionStoreKitServiceError.missingPlans
        }

        return plans
    }

    func purchase(planID: String) async throws -> SubscriptionPurchaseResult {
        let appAccountToken = try appAccountTokenProvider.currentAppAccountToken()
        return try await client.purchase(
            productID: planID,
            appAccountToken: appAccountToken
        )
    }

    func finishPurchase(transactionID: String) async throws {
        try await client.finish(transactionID: transactionID)
    }

    func makeTransactionUpdatesStream() -> AsyncStream<SubscriptionVerifiedPurchase> {
        client.makeTransactionUpdatesStream()
    }
}

enum SubscriptionStoreKitServiceError: Error {
    case missingPlans
    case missingProduct
    case missingTransaction
}

private final class SubscriptionStoreKitClient: SubscriptionStoreKitClientProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var pendingTransactions: [String: Transaction] = [:]
    private let productIDs = Set(SubscriptionCatalog.orderedPlans.map(\.id))

    func products(for productIDs: [String]) async throws -> [SubscriptionStoreKitClientProduct] {
        let products = try await Product.products(for: productIDs)

        return products.map {
            SubscriptionStoreKitClientProduct(
                id: $0.id,
                price: $0.displayPrice
            )
        }
    }

    func purchase(productID: String, appAccountToken: UUID) async throws -> SubscriptionPurchaseResult {
        guard let product = try await Product.products(for: [productID]).first else {
            throw SubscriptionStoreKitServiceError.missingProduct
        }

        let result = try await product.purchase(
            options: [.appAccountToken(appAccountToken)]
        )

        switch result {
        case let .success(verification):
            switch verification {
            case let .verified(transaction):
                let transactionID = String(transaction.id)
                lock.withLock {
                    pendingTransactions[transactionID] = transaction
                }

                return .verified(
                    SubscriptionVerifiedPurchase(
                        productId: productID,
                        transactionId: transactionID,
                        originalTransactionId: String(transaction.originalID),
                        signedTransaction: verification.jwsRepresentation,
                        purchaseDate: transaction.purchaseDate,
                        environment: String(describing: transaction.environment)
                    )
                )

            case .unverified:
                return .unverified
            }

        case .pending:
            return .pending

        case .userCancelled:
            return .cancelled

        @unknown default:
            return .cancelled
        }
    }

    func finish(transactionID: String) async throws {
        guard let transaction = lock.withLock(
            { pendingTransactions[transactionID] }
        ) else {
            throw SubscriptionStoreKitServiceError.missingTransaction
        }

        await transaction.finish()

        _ = lock.withLock {
            pendingTransactions.removeValue(forKey: transactionID)
        }
    }

    func makeTransactionUpdatesStream() -> AsyncStream<SubscriptionVerifiedPurchase> {
        AsyncStream { continuation in
            let observationTask = Task { [weak self] in
                for await verification in Transaction.updates {
                    guard let self,
                          case let .verified(transaction) = verification,
                          self.productIDs.contains(transaction.productID) else {
                        continue
                    }

                    let transactionID = String(transaction.id)
                    self.lock.withLock {
                        self.pendingTransactions[transactionID] = transaction
                    }

                    continuation.yield(
                        SubscriptionVerifiedPurchase(
                            productId: transaction.productID,
                            transactionId: transactionID,
                            originalTransactionId: String(transaction.originalID),
                            signedTransaction: verification.jwsRepresentation,
                            purchaseDate: transaction.purchaseDate,
                            environment: String(describing: transaction.environment)
                        )
                    )
                }
            }

            continuation.onTermination = { _ in
                observationTask.cancel()
            }
        }
    }
}

private extension NSLock {
    func withLock<T>(_ block: () -> T) -> T {
        lock()
        defer { unlock() }
        return block()
    }
}
